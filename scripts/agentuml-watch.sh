#!/usr/bin/env bash
# agentuml-watch — 監聽 diagrams/ 並自動編譯 .puml → output/
#
# Nix 環境：由 flake.nix 透過 substituteAll 將 @PLANTUML@ / @ENTR@ 替換為 store path
# 非 Nix 環境：直接使用系統 PATH 中的 plantuml / entr

PLANTUML="${PLANTUML:-plantuml}"
ENTR="${ENTR:-entr}"

mkdir -p output diagrams
echo "agentUML: Monitoring diagrams/ folder..."

# 初始全量編譯一次
"$PLANTUML" -r --output-dir "$PWD/output" "diagrams/**/*.puml"

# 外層迴圈：entr -d 偵測到 diagrams/ 有新檔案時退出並重啟，
# 讓新建的 .puml 也納入監聽清單；/_ 只編譯觸發變動的那個檔案
while true; do
  find diagrams -name "*.puml" \
    | "$ENTR" -d \
        "$PLANTUML" -v --output-dir "$PWD/output" /_
done
