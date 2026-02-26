#!/usr/bin/env bash
# talkuml-preview — 開啟 imv 預覽 output/，監聽 diagrams/ 自動切換到最新圖片
#
# Nix 環境：由 flake.nix 透過 substituteAll 將 @IMV@ / @INOTIFYWAIT@ 替換為 store path
# 非 Nix 環境：直接使用系統 PATH 中的 imv / inotifywait

IMV="${IMV:-imv}"
IMV_MSG="${IMV_MSG:-imv-msg}"
INOTIFYWAIT="${INOTIFYWAIT:-inotifywait}"


mkdir -p output diagrams

# 方案 A：啟動時只開 output/ 目錄（不使用 -n），避免 imv 在某些情況下 segfault
# 之後靠 diagrams/ 的事件推導 output/<name>.png，再用 imv-msg open 切換
"$IMV" output/ &
IMV_PID=$!

echo "TalkUML: imv started (pid $IMV_PID), watching diagrams/ for changes..."

# 仍記錄啟動時最新的 .puml（純 debug 用）
LATEST_PUML=$(find diagrams -type f -name '*.puml' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2-)
if [ -n "$LATEST_PUML" ]; then
  BASENAME=$(basename "$LATEST_PUML" .puml)
  TARGET="output/$BASENAME.png"
  echo "TalkUML: startup: latest puml=$LATEST_PUML"
  echo "TalkUML: startup: inferred target image=$TARGET"

  # 啟動後立刻嘗試切到最新 diagram 的圖片（避免只印訊息但畫面停在舊圖）
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    [ -f "$TARGET" ] && break
    sleep 1
  done

  if [ -f "$TARGET" ]; then
    echo "TalkUML: startup: opening $TARGET"
    # imv 啟動初期 IPC 可能尚未就緒，重試幾次
    for _ in 1 2 3 4 5 6 7 8 9 10; do
      "$IMV_MSG" "$IMV_PID" open "$TARGET" 2>/dev/null && "$IMV_MSG" "$IMV_PID" goto -1 2>/dev/null && break
      sleep 0.2
    done
  else
    echo "TalkUML: startup: $TARGET not ready yet"
  fi
else
  echo "TalkUML: startup: no puml found"
fi

# 只監聽 diagrams/：
#   close_write → .puml 被修改（entr 觸發單檔編譯）
#   create      → 新 .puml 建立
"$INOTIFYWAIT" -m -r \
  -e close_write -e create -e moved_to \
  --format "%e %w%f" diagrams/ \
  2>/dev/null \
  | while read -r event filename; do
      case "$filename" in
        *.puml)
          # 若 imv crash/被關閉，不要退出 watcher；下次事件再自動重啟
          if [ -n "$IMV_PID" ] && ! kill -0 "$IMV_PID" 2>/dev/null; then
            echo "TalkUML: imv exited, will restart on next event."
            IMV_PID=""
          fi

           echo "TalkUML: event: $event file=$filename"

          # 從 .puml 檔名直接算出對應 PNG 路徑（只取 basename，不包含子目錄）
          BASENAME=$(basename "$filename" .puml)
          TARGET="output/$BASENAME.png"
          echo "TalkUML: event: target image=$TARGET"

          # 等待 plantuml 完成輸出（最多 10 秒）
          for _ in 1 2 3 4 5 6 7 8 9 10; do
            [ -f "$TARGET" ] && break
            sleep 1
          done

          if [ ! -f "$TARGET" ]; then
            echo "TalkUML: warning: $TARGET not found after timeout"
            echo "TalkUML: event: timeout waiting for $TARGET"
            continue
          fi

          # imv 不在時，先重啟 imv（不使用 -n），再切到目標圖片
          if [ -z "$IMV_PID" ] || ! kill -0 "$IMV_PID" 2>/dev/null; then
            echo "TalkUML: event: starting imv (no -n)"
            "$IMV" output/ &
            IMV_PID=$!
            echo "TalkUML: imv started (pid $IMV_PID)"
            # 給 imv 一點時間建立 IPC
            sleep 0.2
          fi

          # 不分 CREATE / CLOSE_WRITE：一律切到該 .puml 對應的圖片
          # 這避免只 reload 當前圖而沒切換到最新編輯的 diagram
          echo "TalkUML: event: open + goto -1"
          "$IMV_MSG" "$IMV_PID" open "$TARGET"
          "$IMV_MSG" "$IMV_PID" goto -1
          ;;
      esac
    done
