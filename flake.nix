{
  description = "agentUML - Reactive D2 development environment";

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

        dev-bin = pkgs.writeShellScriptBin "agentuml-dev" ''
          export D2="${pkgs.d2}/bin/d2"
          export RSVG_CONVERT="${pkgs.librsvg}/bin/rsvg-convert"
          export IMV="${pkgs.imv}/bin/imv"
          export IMV_MSG="${pkgs.imv}/bin/imv-msg"
          export INOTIFYWAIT="${pkgs.inotify-tools}/bin/inotifywait"

          exec bash "${./scripts/agentuml-dev.sh}" "$@"
        '';

      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            d2
            librsvg       # 提供 rsvg-convert：SVG → PNG
            imv           # Wayland 原生圖片預覽器
            inotify-tools # agentuml-dev 監聽 diagrams/ 所需
            dev-bin
          ];

          shellHook = ''
            echo "🎨 Welcome to agentUML Development Environment"
            echo "Available commands:"
            echo "  agentuml-dev - Start D2 watch + preview"
          '';
        };
      }
    );
}
