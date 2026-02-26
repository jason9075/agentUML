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
        # 用 inotifywait 監聽 output/，有新 PNG 寫入就透過 imv-msg 開啟並跳到最新圖片
        preview-script = pkgs.writeShellScriptBin "talkuml-preview" ''
          if [ ! -d "output" ]; then
            echo "Error: output directory not found. Run talkuml-watch first."
            exit 1
          fi

          # 取最新的圖片作為 imv 起始畫面，若 output/ 為空則直接開目錄
          LATEST=$(ls -t output/*.png output/*.svg 2>/dev/null | head -1)
          if [ -n "$LATEST" ]; then
            # -n 指定起始圖片，同時把整個目錄傳入讓 imv 掃描所有圖
            ${pkgs.imv}/bin/imv -n "$LATEST" output/ &
          else
            ${pkgs.imv}/bin/imv output/ &
          fi
          IMV_PID=$!

          echo "TalkUML: imv started (pid $IMV_PID), watching output/ for new images..."

          # 監聽 output/ 目錄：當 PNG/SVG 寫入關閉（close_write）時開啟並切到最新
          ${pkgs.inotify-tools}/bin/inotifywait -m -e close_write --format "%f" output/ 2>/dev/null \
            | while read -r filename; do
                case "$filename" in
                  *.png|*.svg)
                    if kill -0 "$IMV_PID" 2>/dev/null; then
                      # 開啟新圖後立刻跳到清單最後一張（最新加入的）
                      ${pkgs.imv}/bin/imv-msg "$IMV_PID" open "output/$filename"
                      ${pkgs.imv}/bin/imv-msg "$IMV_PID" goto -1
                    else
                      echo "TalkUML: imv exited, stopping preview watcher."
                      exit 0
                    fi
                    ;;
                esac
              done
        '';

        # 一鍵啟動：用 tmux 同時跑 watch（左）與 preview（右）
        # 每次執行都會 kill 舊 session 重新啟動，執行完後自動 detach 回原本 shell
        dev-script = pkgs.writeShellScriptBin "talkuml-dev" ''
          mkdir -p diagrams output

          SESSION="talkuml"

          # 若 session 已存在則強制終止，確保乾淨重啟
          if ${pkgs.tmux}/bin/tmux has-session -t "$SESSION" 2>/dev/null; then
            echo "TalkUML: restarting session..."
            ${pkgs.tmux}/bin/tmux kill-session -t "$SESSION"
          fi

          # 建立新 session（-d 表示 detached，不自動 attach）
          ${pkgs.tmux}/bin/tmux new-session -d -s "$SESSION" -x 220 -y 50
          ${pkgs.tmux}/bin/tmux send-keys -t "$SESSION" "talkuml-watch" Enter

          # 右側 pane 延遲 2 秒後跑 preview（等 output/ 初始化完成）
          ${pkgs.tmux}/bin/tmux split-window -h -t "$SESSION"
          ${pkgs.tmux}/bin/tmux send-keys -t "$SESSION" "sleep 2 && talkuml-preview" Enter

          echo "TalkUML: session '$SESSION' started (detached)."
          echo "  attach : tmux attach -t $SESSION"
          echo "  stop   : tmux kill-session -t $SESSION"
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            plantuml
            entr
            imv           # Wayland 原生圖片預覽器
            inotify-tools # preview 腳本監聽 output/ 新圖片所需
            tmux          # talkuml-dev 一鍵啟動所需
            jre           # PlantUML 依賴 Java
            graphviz      # 用於繪製複雜圖形 (如 state, class diagrams)
            watch-script
            preview-script
            dev-script
          ];

          shellHook = ''
            echo "🎨 Welcome to TalkUML Development Environment"
            echo "Available commands:"
            echo "  talkuml-dev     - Start watch + preview together (tmux)"
            echo "  talkuml-watch   - Start monitoring .puml files and auto-generate images"
            echo "  talkuml-preview - Open the image viewer with auto-reload"
          '';
        };
      }
    );
}
