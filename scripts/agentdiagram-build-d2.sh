#!/usr/bin/env bash
# agentdiagram-build-d2 — 一次性編譯所有 diagrams/ 下的 .d2 檔案

D2="${D2:-d2}"
RSVG_CONVERT="${RSVG_CONVERT:-rsvg-convert}"

mkdir -p diagrams output

shopt -s globstar nullglob

had_match=0
for d2_file in diagrams/**/*.d2; do
  compile_output=""
  svg_target=""
  [ -f "$d2_file" ] || continue
  had_match=1

  relative="${d2_file#diagrams/}"
  target="output/${relative%.d2}.png"

  mkdir -p "$(dirname "$target")"

  svg_target="${target%.png}.tmp.svg"

  if ! compile_output=$("$D2" "$d2_file" "$svg_target" 2>&1); then
    echo "agentDiagram: compile failed: $d2_file" >&2
    echo "$compile_output" >&2
    exit 1
  fi

  if ! compile_output=$("$RSVG_CONVERT" -f png -o "$target" "$svg_target" 2>&1); then
    echo "agentDiagram: svg->png failed: $d2_file" >&2
    echo "$compile_output" >&2
    exit 1
  fi

  rm -f "$svg_target" >/dev/null 2>&1 || true
done

if [ "$had_match" -eq 0 ]; then
  echo "agentDiagram: no .d2 files found under diagrams/" >&2
fi
