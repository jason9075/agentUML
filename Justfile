# TalkUML — task runner
# Run `just` to list available targets.
# Most targets wrap `nix develop --command ...` so you can run them outside the dev shell.

# 預設目標：列出所有指令
default:
    @just --list

# 進入 Nix dev shell
shell:
    nix develop

# 一鍵啟動：tmux 同時跑 watch（左）與 preview（右）
# 若已在 dev shell（direnv/use flake）則不重複 nix develop
dev:
    bash -lc 'if [ -n "${IN_NIX_SHELL:-}" ]; then talkuml-dev; else nix develop --command talkuml-dev; fi'

# 啟動檔案監聽與自動編譯
watch:
    bash -lc 'if [ -n "${IN_NIX_SHELL:-}" ]; then talkuml-watch; else nix develop --command talkuml-watch; fi'

# 開啟圖片預覽器（需先在另一個終端執行 watch）
preview:
    bash -lc 'if [ -n "${IN_NIX_SHELL:-}" ]; then talkuml-preview; else nix develop --command talkuml-preview; fi'

# 一次性編譯所有 diagrams/ 下的 .puml 檔案
build:
    bash -lc 'if [ -z "${IN_NIX_SHELL:-}" ]; then nix develop --command bash -lc '"'"'mkdir -p output && plantuml -o ./output "diagrams/**/*.puml"'"'"'; else mkdir -p output && plantuml -o ./output "diagrams/**/*.puml"; fi'

# 編譯單一圖表，用法：just compile diagrams/foo.puml
compile file:
    bash -lc 'if [ -z "${IN_NIX_SHELL:-}" ]; then nix develop --command bash -lc '"'"'mkdir -p output && plantuml -o ./output "{{file}}"'"'"'; else mkdir -p output && plantuml -o ./output "{{file}}"; fi'

# 清除所有產出的圖片
clean:
    rm -rf output/

# 建立 diagrams/ 目錄（若尚未存在）
init:
    mkdir -p diagrams output
    @echo "Ready. Place .puml files in diagrams/ and run: just watch"

# 驗證 flake.nix 語法
check:
    nix flake check

# 更新 flake inputs（謹慎使用，會修改 flake.lock）
update:
    nix flake update
