#!/usr/bin/env bash
# agentuml-compile-d2 — 編譯單一 D2 圖表

D2="${D2:-d2}"
RSVG_CONVERT="${RSVG_CONVERT:-rsvg-convert}"

if [ $# -ne 1 ]; then
  echo "Usage: agentuml-compile-d2.sh <file.d2>" >&2
  exit 2
fi

d2_file="$1"

if [ ! -f "$d2_file" ]; then
  echo "agentUML: file not found: $d2_file" >&2
  exit 2
fi

case "$d2_file" in
  *.d2) ;;
  *)
    echo "agentUML: expected a .d2 file: $d2_file" >&2
    exit 2
    ;;
esac

mkdir -p diagrams output

relative="${d2_file#diagrams/}"
target="output/${relative%.d2}.png"

mkdir -p "$(dirname "$target")"

svg_target="${target%.png}.tmp.svg"

if ! compile_output=$("$D2" "$d2_file" "$svg_target" 2>&1); then
  echo "agentUML: compile failed: $d2_file" >&2
  echo "$compile_output" >&2
  exit 1
fi

if ! compile_output=$("$RSVG_CONVERT" -f png -o "$target" "$svg_target" 2>&1); then
  echo "agentUML: svg->png failed: $d2_file" >&2
  echo "$compile_output" >&2
  exit 1
fi

rm -f "$svg_target" >/dev/null 2>&1 || true

echo "$target"
