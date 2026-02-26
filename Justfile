# TalkUML — task runner
# Run `just` to list available targets.
# All commands assume you are inside `nix develop` (or direnv is active).

# 預設目標：列出所有指令
default:
    @just --list

# 進入 Nix dev shell
shell:
    nix develop

# 啟動檔案監聽與自動編譯
watch:
    talkuml-watch

# 開啟圖片預覽器（需先在另一個終端執行 watch）
preview:
    talkuml-preview

# 一次性編譯所有 diagrams/ 下的 .puml 檔案
build:
    mkdir -p output
    plantuml -o ./output "diagrams/**/*.puml"

# 編譯單一圖表，用法：just compile diagrams/foo.puml
compile file:
    mkdir -p output
    plantuml -o ./output "{{file}}"

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
