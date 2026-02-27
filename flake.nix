{
  description = "agentUML - Reactive PlantUML development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # 從 scripts/ 讀取腳本內容，供 Nix dev shell 產生同名指令
        # 這些腳本也能在非 Nix 環境直接執行（依賴系統 PATH 內的工具）
        stripShebang = script: builtins.replaceStrings [ "#!/usr/bin/env bash\n" ] [ "" ] script;

        watch-bin = pkgs.writeShellScriptBin "agentuml-watch" (
          stripShebang (builtins.readFile ./scripts/agentuml-watch.sh)
        );

        preview-bin = pkgs.writeShellScriptBin "agentuml-preview" (
          stripShebang (builtins.readFile ./scripts/agentuml-preview.sh)
        );

        dev-bin = pkgs.writeShellScriptBin "agentuml-dev" (
          stripShebang (builtins.readFile ./scripts/agentuml-dev.sh)
        );
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            plantuml
            entr
            imv           # Wayland 原生圖片預覽器
            inotify-tools # preview 腳本監聽 diagrams/ 所需
            tmux          # agentuml-dev 一鍵啟動所需
            jre           # PlantUML 依賴 Java
            graphviz      # 用於繪製複雜圖形 (如 state, class diagrams)
            watch-bin
            preview-bin
            dev-bin
          ];

          shellHook = ''
            echo "🎨 Welcome to agentUML Development Environment"
            echo "Available commands:"
            echo "  agentuml-dev     - Start watch + preview together (tmux)"
            echo "  agentuml-watch   - Start monitoring .puml files and auto-generate images"
            echo "  agentuml-preview - Open the image viewer with auto-reload"
          '';
        };
      }
    );
}
