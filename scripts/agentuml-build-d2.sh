#!/usr/bin/env bash
# agentuml-build-d2 — 一次性編譯所有 diagrams/ 下的 .d2 檔案

D2="${D2:-d2}"

mkdir -p diagrams output

shopt -s globstar nullglob

had_match=0
for d2_file in diagrams/**/*.d2; do
  [ -f "$d2_file" ] || continue
  had_match=1

  relative="${d2_file#diagrams/}"
  target="output/${relative%.d2}.png"

  mkdir -p "$(dirname "$target")"

  if ! "$D2" "$d2_file" "$target"; then
    echo "agentUML: compile failed: $d2_file" >&2
    exit 1
  fi
done

if [ "$had_match" -eq 0 ]; then
  echo "agentUML: no .d2 files found under diagrams/" >&2
fi
