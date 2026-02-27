# agentDiagram

Reactive diagram authoring environment (D2-first) powered by Nix Flakes.
Save a `.d2` file, the rendered PNG updates automatically.

Chinese README: `README-ZHTW.md`

## Requirements

- [Nix](https://nixos.org/download) with Flakes enabled
- Wayland session (for `imv` preview)

## Quick Start (recommended: with opencode)

```sh
# Initialize folders
just init

# Start watch + compile + preview
just dev
```

Then use opencode to generate/iterate diagram source (`.d2`) via the `draw` agent or `d2-*` skills.
When `diagrams/*.d2` is saved, `agentdiagram-dev` recompiles to `output/<name>.png` and switches the `imv` preview.

> If you use direnv (`use flake`) and are already in the dev shell, `Justfile` runs `agentdiagram-*` directly.
> Otherwise it wraps commands with `nix develop --command ...`.

## Directory Layout

```text
agentDiagram/
├── flake.nix        # Environment definition (single source of truth)
├── flake.lock       # Pinned Nix input revisions
├── Justfile         # Task runner wrapper
├── scripts/         # Portable scripts for non-Nix environments
├── diagrams/        # Local-only .d2 sources (gitignored)
└── output/          # Rendered images (gitignored)
```

## Common Commands

| Command | Purpose |
|---|---|
| `just dev` | Start watch + compile + preview |
| `just build` | Compile all `.d2` under `diagrams/` |
| `just compile <file>` | Compile a single `.d2` |
| `just clean` | Remove `output/` |
| `just check` | Run `nix flake check` |

## Writing Diagrams

Recommended: let opencode write/modify `diagrams/*.d2` (text → diagram).
You can also create `.d2` files manually:

```d2
# diagrams/my-diagram.d2
User -> Service: request
Service -> User: response
```

## Non-Nix Usage

You can run scripts directly if you already have the tools installed.

### Required tools

- `d2`
- `rsvg-convert` (from `librsvg`, used for SVG → PNG)
- `inotifywait` (from `inotify-tools`)
- `imv`, `imv-msg`

### Run

```sh
mkdir -p diagrams output
bash ./scripts/agentdiagram-dev.sh
```

## Samples

### Workflow (Sequence)

- Source: `imgs/sequence.d2`
- Output: `imgs/sequence.png`
- Render: `d2 --layout elk --theme 303 imgs/sequence.d2 - | rsvg-convert -f png -o imgs/sequence.png -`

![SEQUENCE](./imgs/sequence.png)

### GOT

![GOT_ASK](./imgs/got_ask.png)
![GOT_OUTPUT](./imgs/got_output.png)

## License

MIT
