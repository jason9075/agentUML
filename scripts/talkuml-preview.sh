#!/usr/bin/env bash
# talkuml-preview — 開啟 imv 預覽 output/，監聽 diagrams/ 自動切換到最新圖片
#
# Nix 環境：由 flake.nix 透過 substituteAll 將 @IMV@ / @INOTIFYWAIT@ 替換為 store path
# 非 Nix 環境：直接使用系統 PATH 中的 imv / inotifywait

IMV="${IMV:-imv}"
IMV_MSG="${IMV_MSG:-imv-msg}"
INOTIFYWAIT="${INOTIFYWAIT:-inotifywait}"

mkdir -p output

# 找 diagrams/ 最新修改的 .puml，推算對應的 output/*.png
# 若 output/*.png 不存在就不開 imv，等 talkuml-watch 編譯後由 inotifywait 事件再開圖
LATEST_PUML=$(ls -t diagrams/**/*.puml diagrams/*.puml 2>/dev/null | head -1)
if [ -z "$LATEST_PUML" ]; then
  echo "TalkUML: no .puml files found in diagrams/, waiting for changes..."
  IMV_PID=""
else
  BASENAME=$(basename "${LATEST_PUML%.puml}")
  TARGET="output/$BASENAME.png"
  if [ -f "$TARGET" ]; then
    "$IMV" -n "$TARGET" output/ &
    IMV_PID=$!
  else
    echo "TalkUML: $TARGET not ready yet, will open when compiled."
    IMV_PID=""
  fi
fi

if [ -n "$IMV_PID" ]; then
  echo "TalkUML: imv started (pid $IMV_PID), watching diagrams/ for changes..."
else
  echo "TalkUML: watching diagrams/ for changes..."
fi

# 只監聽 diagrams/：
#   close_write → .puml 被修改（entr 觸發單檔編譯）
#   create      → 新 .puml 建立
"$INOTIFYWAIT" -m \
  -e close_write -e create \
  --format "%e %f" diagrams/ \
  2>/dev/null \
  | while read -r event filename; do
      case "$filename" in
        *.puml)
          # 若 imv 已開，確認它還在；若使用者關閉就停止 watcher
          if [ -n "$IMV_PID" ] && ! kill -0 "$IMV_PID" 2>/dev/null; then
            echo "TalkUML: imv exited, stopping preview watcher."
            exit 0
          fi

          # 從 .puml 檔名直接算出對應 PNG 路徑
          BASENAME="${filename%.puml}"
          TARGET="output/$BASENAME.png"

          # 等待 plantuml 完成輸出（最多 10 秒）
          for _ in 1 2 3 4 5 6 7 8 9 10; do
            [ -f "$TARGET" ] && break
            sleep 1
          done

          if [ ! -f "$TARGET" ]; then
            echo "TalkUML: warning: $TARGET not found after timeout"
            continue
          fi

          # imv 尚未啟動（啟動時找不到圖檔），現在圖檔已備妥，直接開啟
          if [ -z "$IMV_PID" ] || ! kill -0 "$IMV_PID" 2>/dev/null; then
            "$IMV" -n "$TARGET" output/ &
            IMV_PID=$!
            echo "TalkUML: imv started (pid $IMV_PID)"
            continue
          fi

          case "$event" in
            CLOSE_WRITE,CLOSE)
              # 修改現有檔案：reload 原地刷新，不重複 open
              "$IMV_MSG" "$IMV_PID" reload
              ;;
            CREATE)
              # 新檔案：加入 imv 清單並切換過去
              "$IMV_MSG" "$IMV_PID" open "$TARGET"
              "$IMV_MSG" "$IMV_PID" goto -1
              ;;
          esac
          ;;
      esac
    done
