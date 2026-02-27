#!/usr/bin/env bash
# agentuml-dev — 用 tmux 同時啟動 watch（左）與 preview（右）
#
# Nix 環境：由 flake.nix 透過 substituteAll 將 @TMUX@ 替換為 store path
# 非 Nix 環境：直接使用系統 PATH 中的 tmux

TMUX_BIN="${TMUX_BIN:-tmux}"

mkdir -p diagrams output

SESSION="agentuml"

# 若 session 已存在則強制終止，確保乾淨重啟
if "$TMUX_BIN" has-session -t "$SESSION" 2>/dev/null; then
  echo "agentUML: restarting session..."
  "$TMUX_BIN" kill-session -t "$SESSION"
fi

# 建立新 session（-d 表示 detached，不自動 attach）
"$TMUX_BIN" new-session -d -s "$SESSION" -x 220 -y 50
"$TMUX_BIN" send-keys -t "$SESSION" "agentuml-watch" Enter

# 右側 pane 延遲 2 秒後跑 preview（等 output/ 初始化完成）
"$TMUX_BIN" split-window -h -t "$SESSION"
"$TMUX_BIN" send-keys -t "$SESSION" "sleep 2 && agentuml-preview" Enter

echo "agentUML: session '$SESSION' started (detached)."
echo "  attach : tmux attach -t $SESSION"
echo "  stop   : tmux kill-session -t $SESSION"
