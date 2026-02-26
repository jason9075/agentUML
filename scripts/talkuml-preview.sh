#!/usr/bin/env bash
# talkuml-preview — 開啟 imv 預覽 output/，監聽 diagrams/ 自動切換到最新圖片
#
# Nix 環境：由 flake.nix 透過 substituteAll 將 @IMV@ / @INOTIFYWAIT@ 替換為 store path
# 非 Nix 環境：直接使用系統 PATH 中的 imv / inotifywait

IMV="${IMV:-imv}"
IMV_MSG="${IMV_MSG:-imv-msg}"
INOTIFYWAIT="${INOTIFYWAIT:-inotifywait}"

if [ ! -d "output" ]; then
  echo "Error: output directory not found. Run talkuml-watch first."
  exit 1
fi

# 取最新的圖片作為 imv 起始畫面，若 output/ 為空則直接開目錄
LATEST=$(ls -t output/*.png output/*.svg 2>/dev/null | head -1)
if [ -n "$LATEST" ]; then
  "$IMV" -n "$LATEST" output/ &
else
  "$IMV" output/ &
fi
IMV_PID=$!

echo "TalkUML: imv started (pid $IMV_PID), watching diagrams/ for changes..."

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
          if ! kill -0 "$IMV_PID" 2>/dev/null; then
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
