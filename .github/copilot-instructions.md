# Copilot Instructions — dev-setup

This file documents the conventions, patterns, and design decisions for this project.
Use this as the reference when suggesting changes, generating new modules, or reviewing scripts.

---

## Project Purpose

A modular, idempotent, and versionable developer environment setup for Fedora/RHEL-based systems.
Focused exclusively on developer productivity: terminal, Git, containers, and .NET SDK.
GPU configuration is supported via a dedicated standalone script and explicit setup flags.
Power mode / energy tuning remains explicitly out of scope.

---

## File Structure

```
dev-setup/
├── setup.sh                 # Orchestrator — parses flags, calls modules in order
├── scripts/
│   ├── base.sh              # CLI productivity tools (dnf packages)
│   ├── terminal.sh          # Zsh + Oh My Zsh + plugins + Starship + dotfile deploy
│   ├── dev.sh               # LazyGit + .NET SDK
│   ├── containers.sh        # Podman stack + Docker compat + docker compose + optional UI
│   └── gpu.sh               # Standalone NVIDIA setup with profile/action arguments
└── dotfiles/
    └── .zshrc               # Shell config deployed by terminal.sh via cp
```

`originais/` contains the original reference scripts and must not be modified.

---

## Core Design Rules

### Idempotency
Every installation step must be guarded. Never install or configure something that already exists.

Guards to use (by scenario):
- `command -v <binary> &>/dev/null` — binary already in PATH
- `[ ! -d "$HOME/path" ]` — directory does not exist
- `dnf install -y` — dnf is natively idempotent (skips installed packages)
- `flatpak install -y` — flatpak skips already-installed apps
- `systemctl ... || true` — prevents abort if socket/service fails

### Error handling
- Always use `set -euo pipefail` at the top of every script.
- Use `|| true` only for non-critical steps (socket, chsh) where failure is acceptable.
- Use explicit `[ERROR]` messages and `exit 1` for unrecoverable states (unsupported arch, etc).
- Never use `|| true` on critical installation steps.

### Architecture awareness
- Any binary download must detect arch with `uname -m` and map to the correct label.
- Supported: `x86_64`, `aarch64` (arm64).
- Unsupported arch: print `[ERROR]` and `exit 1`.

---

## Logging Conventions

All scripts must use consistent log prefixes for clarity during execution:

| Prefix | Meaning |
|---|---|
| `[INFO]` | Step is about to run |
| `[OK]` | Step completed successfully |
| `[SKIP]` | Step was skipped (already done) |
| `[WARN]` | Non-fatal issue, execution continues |
| `[ERROR]` | Fatal issue, script should exit |

---

## Module Conventions

### setup.sh
- Parses optional flags before calling any module.
- Current flags: `--ui`, `--gpu-alienware`, `--gpu-lenovo`.
- Passes flags as positional arguments to the relevant module (`containers.sh "$INSTALL_UI"`).
- Calls `gpu.sh` only when a GPU flag is provided.
- Never contains installation logic directly.

### base.sh
- Only `dnf install -y` calls.
- No guards needed — dnf is idempotent natively.

### terminal.sh
- Installs zsh, Oh My Zsh, plugins, Starship.
- Deploys `dotfiles/.zshrc` via `cp` (intentional — always syncs dotfile on run).
- Plugins guarded by `[ ! -d ... ]`.
- Oh My Zsh guarded by `[ ! -d "$HOME/.oh-my-zsh" ]`.
- Starship guarded by `command -v starship`.

### dev.sh
- LazyGit: guarded by `command -v lazygit`, arch-aware download.
- dotnet: guarded by `command -v dotnet`.

### containers.sh
- Accepts `$1` as `INSTALL_UI` (default: `false`).
- Installation order:
  1. `podman` + `podman-compose` (via dnf)
  2. `podman-docker` (Docker CLI shim, guarded by `command -v docker`)
  3. `podman.socket` (systemctl user service)
  4. `docker compose` plugin (try dnf → fallback to manual binary install)
  5. Podman Desktop via Flatpak (only if `INSTALL_UI=true`)

### gpu.sh
- Accepts `$1` as `GPU_PROFILE` and `$2` as `ACTION` (`install|undo|reset`, default: `install`).
- Must fail fast for unsupported profiles.
- Current profiles:
  1. `alienware` (implemented)
  2. `lenovo` (reserved, intentionally returns error until implemented)
- Must avoid any power mode tuning or always-on GPU policy.

---

## Container Stack Design

```
User command          Underlying runtime
────────────────────  ─────────────────────────────────
docker ps           → Podman (via podman-docker shim)
docker compose up   → Docker Compose plugin → Podman socket
podman-compose up   → podman-compose (legacy, kept as fallback)
```

The goal is full Docker CLI compatibility without installing Docker Engine.

---

## Dotfiles

`dotfiles/.zshrc` is the single source of truth for shell configuration.
It is deployed on every run of `terminal.sh` via `cp dotfiles/.zshrc ~/.zshrc`.

### Alias conventions
- Git aliases: `gs`, `ga`, `gc`, `gp`
- Container aliases use `docker compose` (not `podman-compose`) since V3:
  - `dc` = `docker compose`
  - `dcu` = `docker compose up -d`
  - `dcd` = `docker compose down`
- File/nav aliases: `ls` = `eza --icons`, `ll` = `eza -lah --icons`, `cat` = `bat`

---

## Language and Comments

- All script **comments** must be written in English.
- All `echo` output messages can use emojis for visual clarity.
- `README.md` must be written entirely in English.
- No documentation markdown files should be created unless explicitly requested.

---

## Versioning Convention

| Version | What changed |
|---|---|
| V1 | Original monolithic script (see `originais/setup-dev.sh`) |
| V2 | Improved idempotency, logging, arch detection, `.zshrc` guard (see `originais/setup-dev-v2.sh`) |
| V3 | Modular structure, `--ui` flag, Docker compat (`podman-docker`), `docker compose` plugin with fallback |
| V3.1 | Optional standalone GPU module with profile-based flags and install/undo/reset actions |

When evolving to a new version:
- Increment what changes; keep working parts intact.
- Do not break existing modules.
- Add new capabilities as additive changes (new guards, new steps).
- Keep original scripts in `originais/` untouched.

---

## What Is Intentionally Not Included

- Power mode / performance tuning
- Docker Engine (replaced by Podman)
- Docker Desktop
- VS Code extension management (manual or separate concern)
- Kubernetes / Dev Containers (planned for a future version)
