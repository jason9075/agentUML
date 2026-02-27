#!/usr/bin/env bash
# agentuml-dev — 單一程序：監聽 diagrams/ → 編譯 → 自動切換 imv 顯示最新圖
#
# 需求：plantuml、inotifywait(inotify-tools)、imv、imv-msg

PLANTUML="${PLANTUML:-plantuml}"
IMV="${IMV:-imv}"
IMV_MSG="${IMV_MSG:-imv-msg}"
INOTIFYWAIT="${INOTIFYWAIT:-inotifywait}"

mkdir -p diagrams output

IMV_PID=""

start_imv() {
  "$IMV" output/ &
  IMV_PID=$!
}

ensure_imv_running() {
  if [ -n "$IMV_PID" ] && kill -0 "$IMV_PID" 2>/dev/null; then
    return 0
  fi
  IMV_PID=""
  start_imv

  # 給 imv 一點時間建立 IPC
  sleep 0.2
}

open_image() {
  local target="$1"

  # IPC 可能尚未就緒，重試幾次
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    "$IMV_MSG" "$IMV_PID" open "$target" 2>/dev/null && "$IMV_MSG" "$IMV_PID" goto -1 2>/dev/null && return 0
    sleep 0.2
  done

  return 1
}

compile_and_show() {
  local puml_file="$1"
  local basename
  local target

  basename=$(basename "$puml_file" .puml)
  target="output/$basename.png"

  if ! "$PLANTUML" -v --output-dir "$PWD/output" "$puml_file" >/dev/null 2>&1; then
    echo "agentUML: compile failed: $puml_file" >&2
    return 1
  fi

  for _ in 1 2 3 4 5 6 7 8 9 10; do
    [ -f "$target" ] && break
    sleep 1
  done

  if [ ! -f "$target" ]; then
    echo "agentUML: output not found: $target" >&2
    return 1
  fi

  ensure_imv_running
  if ! open_image "$target"; then
    echo "agentUML: imv-msg failed: $target" >&2
    return 1
  fi
}

# 啟動 imv 並嘗試切到最新修改的圖
ensure_imv_running

LATEST_PUML=$(find diagrams -type f -name '*.puml' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2-)
if [ -n "$LATEST_PUML" ]; then
  compile_and_show "$LATEST_PUML" || true
fi

echo "agentUML: watching diagrams/ (compile + preview in one process)"

# 只監聽 diagrams/：
#   close_write → .puml 被修改
#   create/moved_to → atomic save 或新檔案
#
# 用去抖避免同一個檔案的連續事件造成重複編譯。
LAST_FILE=""
LAST_AT="0"

"$INOTIFYWAIT" -m -r \
  -e close_write -e create -e moved_to \
  --format "%e %w%f" diagrams/ \
  2>/dev/null \
  | while read -r event filename; do
      case "$filename" in
        *.puml)
          now=$(date +%s%3N 2>/dev/null || date +%s000)
          if [ "$filename" = "$LAST_FILE" ] && [ $((now - LAST_AT)) -lt 300 ]; then
            continue
          fi
          LAST_FILE="$filename"
          LAST_AT="$now"

          compile_and_show "$filename" || true
          ;;
      esac
    done
