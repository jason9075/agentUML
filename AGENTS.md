# AGENTS.md — TalkUML

Instructions for agentic coding agents operating in this repository.

---

## Project Overview

TalkUML is a **Nix Flake dev environment** for reactive PlantUML diagram authoring.
It is not an application — there is no runtime code, no package.json, no build step.
The entire project is orchestrated through `flake.nix`.

**Tech stack:**
- **Nix Flakes** — environment definition and tooling orchestration
- **PlantUML** — diagram-as-code DSL (`.puml` / `.wsd` files)
- **entr** — inotify-based file watcher
- **imv** — Wayland 原生圖片檢視器
- **Graphviz** — backend for state, class, and component diagrams
- **JRE** — Java runtime required by PlantUML

---

## Directory Structure

```
talkuml/
├── flake.nix        # Full environment definition (single source of truth)
├── flake.lock       # Pinned Nix input revisions — commit changes to this
├── guildlines       # Chinese-language workflow design doc (zh-TW)
├── diagrams/        # Source .puml files (create this directory as needed)
└── output/          # Generated PNG/SVG images (gitignored, auto-created)
```

`diagrams/` and `output/` are not committed; `output/` is auto-created by `talkuml-watch`.

---

## Environment Setup

Always enter the dev shell before running any commands:

```sh
nix develop
# or, with direnv:
direnv allow
```

Do **not** install tools globally. All tooling is pinned in `flake.nix`.

---

## Available Commands

These two commands are exposed as binaries inside the dev shell:

| Command | Purpose |
|---|---|
| `talkuml-watch` | Compile all `.puml` files to `output/`, then watch `diagrams/` for changes |
| `talkuml-preview` | Open `output/` in `feh` with 1-second auto-reload |

Run them in two separate terminals:

```sh
# Terminal 1 — compiler + watcher
talkuml-watch

# Terminal 2 — image viewer
talkuml-preview
```

A `justfile` wraps all common tasks — run `just` to list targets.

---

## PlantUML Diagram Authoring

### File placement

- Source diagrams go in `diagrams/` with the `.puml` extension.
- Subdirectories are supported: `diagrams/auth/login.puml` is valid.
- Output images are placed in `output/` with the same basename.

### Minimal diagram template

```plantuml
@startuml diagram-name
' Use kebab-case for diagram names
title My Diagram

actor User
participant Service

User -> Service : request
Service --> User : response

@enduml
```

### Diagram types and their Graphviz dependency

| Diagram type | Requires Graphviz |
|---|---|
| Sequence | No |
| Use case | No |
| Activity | No |
| Class | Yes |
| State | Yes |
| Component | Yes |
| Deployment | Yes |

---

## Nix Flake Conventions

### Modifying `flake.nix`

- **Indentation:** 2 spaces throughout.
- **String literals:** Double-quoted Nix strings for short values; `''...''` (indented strings) for multi-line shell scripts.
- **Comments:** Written in Traditional Chinese (zh-TW) for inline annotations; English for structural headings if needed.
- **Attribute naming:** `camelCase` for Nix built-in attributes (`buildInputs`, `shellHook`, `devShells`). `kebab-case` for let-bindings and shell script bin names (e.g., `watch-script`, `talkuml-watch`).
- **Input naming:** Use short, lowercase names (`nixpkgs`, `utils`).

### Adding a new tool

1. Add it to the `buildInputs` list in `devShells.default`.
2. Reference it as `pkgs.<attribute-name>` — never hard-code store paths.
3. If it needs a wrapper script, follow the `writeShellScriptBin` pattern already used for `watch-script` and `preview-script`.
4. Update `shellHook` to mention the new command.
5. Run `nix flake update` only if a new input is added; otherwise leave `flake.lock` as-is.

### Shell scripts inside `writeShellScriptBin`

- Use `${pkgs.tool}/bin/tool` for all tool references — never rely on `$PATH`.
- Guard against missing directories with `[ -d "..." ]` checks.
- Prefer `echo "Error: ..."` with a descriptive message over silent failures.
- Do not add `set -euo pipefail` unless the script has meaningful cleanup logic; keep it simple.

---

## Commit Conventions

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add component diagram support
fix: correct output path for nested diagrams
chore: update nixpkgs input to latest unstable
docs: update guildlines with new workflow notes
```

### `.gitignore` requirements

The following must **never** be committed:
- `output/` — generated images
- `.env`, `*.secret`, `opencode.json` — secrets

---

## Agent Task Guidelines

1. **Prefer editing `flake.nix`** over creating new files. The flake is the single source of truth.
2. **Do not create `package.json` or `Makefile`** unless the project explicitly expands to include JS/TS or other tooling. The `justfile` is the task runner — add new targets there instead of creating ad-hoc scripts.
3. **Validate Nix syntax** after editing `flake.nix` by running `nix flake check` inside the dev shell.
4. **Do not run `nix flake update`** unless explicitly asked — it changes `flake.lock` and could break reproducibility.
5. **Diagram files are the work product.** When asked to create a diagram, write a well-formed `.puml` file in `diagrams/` and confirm it compiles with `plantuml diagrams/<file>.puml -o ./output`.
6. **Respect zh-TW comments** in `flake.nix` — preserve them when editing surrounding code.
7. **No test runner exists.** Manual verification means: run `talkuml-watch`, save a `.puml` file, confirm a `.png` appears in `output/`.
