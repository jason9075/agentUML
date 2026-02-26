{
  description = "TalkUML - Reactive PlantUML development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        # 定義自動監聽腳本
        watch-script = pkgs.writeShellScriptBin "talkuml-watch" ''
          mkdir -p output
          echo "TalkUML: Monitoring diagrams/ folder..."
          
          # 初始編譯一次
          ${pkgs.plantuml}/bin/plantuml -o ./output "diagrams/**/*.puml"

          # 使用 entr 監控變動
          # -r 會在檔案列表變動時重啟
          # /_ 代表觸發變動的那個檔案
          find diagrams -name "*.puml" | ${pkgs.entr}/bin/entr -r ${pkgs.plantuml}/bin/plantuml -v -o ../output /_
        '';

        # 啟動預覽器的腳本（使用 imv，原生支援 Wayland）
        preview-script = pkgs.writeShellScriptBin "talkuml-preview" ''
          if [ -d "output" ]; then
            # imv-wayland 會監控目錄，檔案更新後按 R 或透過 imv-msg 重載
            ${pkgs.imv}/bin/imv output/
          else
            echo "Error: output directory not found. Run talkuml-watch first."
          fi
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            plantuml
            entr
            imv  # Wayland 原生圖片預覽器
            jre # PlantUML 依賴 Java
            graphviz # 用於繪製複雜圖形 (如 state, class diagrams)
            watch-script
            preview-script
          ];

          shellHook = ''
            echo "🎨 Welcome to TalkUML Development Environment"
            echo "Available commands:"
            echo "  talkuml-watch   - Start monitoring .puml files and auto-generate images"
            echo "  talkuml-preview - Open the image viewer with auto-reload"
          '';
        };
      }
    );
}
