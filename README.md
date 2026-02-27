# agentDiagram

以 Nix Flake 驅動的響應式 Diagram-as-code 圖表開發環境（**D2**）。儲存 `.d2` 檔案，圖片立即自動更新。

## 需求

- [Nix](https://nixos.org/download)（需啟用 Flakes）
- Wayland 顯示環境（`imv` 預覽器使用）

## 快速開始（建議：搭配 opencode）

```sh
# 初始化目錄
just init

# 一鍵啟動監聽 + 預覽
just dev
```

接著用 opencode 產生/修改圖表文字（`.d2`），例如使用 `draw` agent 或 `d2-*` skills，讓它把檔案寫到 `diagrams/`。
存檔後 `agentdiagram-dev` 會自動編譯成 `output/<name>.png` 並切換 `imv` 預覽。

> 若你用 direnv（`use flake`）已進入 dev shell，`Justfile` 會直接跑 `agentdiagram-*`；否則才會自動用 `nix develop --command ...` 啟動環境。

之後只要在 `diagrams/` 內儲存任何 `.d2` 檔案，`output/` 內的圖片就會自動更新，`imv` 預覽視窗同步切換。

> `just dev` 會啟動 `agentdiagram-dev`：單一程序同時負責編譯與預覽。

### 預覽行為

- `agentdiagram-dev` 會監聽 `diagrams/` 的 `.d2` 變更，編譯後用 `imv-msg` 自動切到對應的 `output/<name>.png`。
- 若你用 direnv 的 `use flake`（pure）修改了 `scripts/` 或 `flake.nix`，需要 `git add` + `direnv reload`，並重新執行 `just dev` 才會套用到新的 `/nix/store` wrapper。

## 目錄結構

```
agentDiagram/
├── flake.nix        # 環境定義（唯一事實來源）
├── flake.lock       # 鎖定的 Nix input 版本
├── Justfile         # 常用指令包裝
├── scripts/         # 非 Nix 環境可直接執行的腳本
├── diagrams/        # 放置 .d2 原始檔
└── output/          # 自動產生的 PNG/SVG（已 gitignore）
```

## 常用指令

> 在沒有 direnv 的情況下，`Justfile` 會用 `nix develop --command ...` 呼叫 `agentdiagram-*` 指令。非 Nix 環境請參考下方「非 Nix 環境使用」。

| 指令 | 說明 |
|---|---|
| `just dev` | **一鍵啟動**編譯 + 預覽（單一程序）|
| `just build` | 一次性編譯所有 `.d2` |
| `just compile <file>` | 編譯單一 `.d2` 圖表 |
| `just clean` | 清除 `output/` |
| `just check` | 驗證 `flake.nix` 語法 |

## 撰寫圖表

本專案建議用 opencode 生成/迭代 `diagrams/*.d2`（文字 → 圖），你也可以手動建立 `.d2` 檔案：

```d2
# diagrams/my-diagram.d2
User -> Service: 發送請求
Service -> User: 回傳結果
```



## 非 Nix 環境使用

如果你在沒有 Nix 的環境也想使用本專案流程，可以直接執行 `scripts/` 內的腳本。

### 需要的工具

請確保以下指令在 `$PATH` 中可用：
- `d2`
- `rsvg-convert`（通常來自 `librsvg`，用於 SVG → PNG）
- `inotifywait`（通常來自 `inotify-tools`）
- `imv`、`imv-msg`

### 用法

```sh
# 初始化目錄
mkdir -p diagrams output

# 一鍵啟動（預設 D2）
bash ./scripts/agentdiagram-dev.sh


```

如果你希望沿用 `Justfile`，可自行把 `scripts/` 加到 PATH：

```sh
export PATH="$PWD/scripts:$PATH"
just dev
```

## 工具鏈

| 工具 | 用途 |
|---|---|
| [D2](https://d2lang.com) | `.d2` → PNG/SVG 編譯器 |
| [inotify-tools](https://github.com/inotify-tools/inotify-tools) | 檔案變動監聽 (`inotifywait`) |
| [imv](https://sr.ht/~exec64/imv/) | Wayland 原生圖片預覽（目錄瀏覽） |
| [Nix Flakes](https://nixos.wiki/wiki/Flakes) | 可重現的開發環境 |

## Sample

### Workflow（Sequence）

`agentdiagram-dev` 的本機工作流（建議搭配 opencode）：Prompt → 產生/修改 `.d2` → 自動編譯 → 自動預覽。

- Source: `imgs/sequence.d2`
- Output: `imgs/sequence.png`
- Render: `d2 --layout elk --theme 303 imgs/sequence.d2 - | rsvg-convert -f png -o imgs/sequence.png -`

![SEQUENCE](./imgs/sequence.png)

### GOT

詢問冰與火之歌的人物關係圖
![GOT_ASK](./imgs/got_ask.png)
![GOT_OUTPUT](./imgs/got_output.png)

## License

MIT
