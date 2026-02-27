# agentUML — task runner
# Run `just` to list available targets.
# Most targets wrap `nix develop --command ...` so you can run them outside the dev shell.

# 預設目標：列出所有指令
default:
    @just --list

# 進入 Nix dev shell
shell:
    nix develop

# 一鍵啟動：單一程序同時跑編譯 + 預覽
# 若已在 dev shell（direnv/use flake）則不重複 nix develop
dev:
    bash -lc 'if [ -n "${IN_NIX_SHELL:-}" ]; then agentuml-dev; else nix develop --command agentuml-dev; fi'

# 一次性編譯所有 diagrams/ 下的 .d2 檔案（預設）
build:
    bash -lc 'if [ -z "${IN_NIX_SHELL:-}" ]; then nix develop --command bash ./scripts/agentuml-build-d2.sh; else bash ./scripts/agentuml-build-d2.sh; fi'

# 編譯單一圖表（預設 D2），用法：just compile diagrams/foo.d2
compile file:
    bash -lc 'if [ -z "${IN_NIX_SHELL:-}" ]; then nix develop --command bash ./scripts/agentuml-compile-d2.sh "{{file}}"; else bash ./scripts/agentuml-compile-d2.sh "{{file}}"; fi'


# 清除所有產出的圖片
clean:
    rm -rf output/

# 建立 diagrams/ 目錄（若尚未存在）
init:
    mkdir -p diagrams output
    @echo "Ready. Place .d2 files in diagrams/ and run: just dev"

# 驗證 flake.nix 語法
check:
    nix flake check

# 更新 flake inputs（謹慎使用，會修改 flake.lock）
update:
    nix flake update
