# Dev Setup — V3 (Modular, Idempotent, Versionable)

Modular developer environment setup for Fedora/RHEL-based systems.
All scripts are idempotent — safe to run multiple times on a fresh or already-configured machine.

Scope: **developer productivity only** — terminal, Git, containers, .NET SDK.
Out of scope: GPU configuration, power management.

## Project Structure

```text
dev-setup/
├── setup.sh                  # Orchestrator — runs all modules in order
├── scripts/
│   ├── base.sh               # CLI productivity tools
│   ├── terminal.sh           # Zsh + Oh My Zsh + Starship + dotfile
│   ├── dev.sh                # LazyGit + .NET SDK
│   └── containers.sh         # Podman full stack + Docker compat + optional UI
└── dotfiles/
    └── .zshrc                # Shell configuration deployed by terminal.sh
```

## What Is Included

| Category | Tools |
|---|---|
| Base CLI | `git`, `curl`, `wget`, `unzip` |
| Productivity CLI | `fzf`, `ripgrep`, `bat`, `eza`, `zoxide` |
| Terminal stack | `zsh`, Oh My Zsh, autosuggestions, syntax highlighting, `starship` |
| Dev tools | `lazygit`, `.NET SDK 10` |
| Containers | `podman`, `podman-compose`, `podman-docker`, `docker compose` plugin, `podman.socket` |
| Optional UI | Podman Desktop (Flatpak, via `--ui` flag) |

## How To Run

```bash
# 1. Clone your repository
git clone https://github.com/rdpresser/setup-dev.git
cd setup-dev/dev-setup

# 2. Make scripts executable
chmod +x setup.sh scripts/*.sh

# 3a. Standard setup (no UI)
./setup.sh

# 3b. Full setup with Podman Desktop UI
./setup.sh --ui

# 4. Restart your session to apply the new shell
logout
```

> **`--ui` flag**: installs Podman Desktop via Flatpak. The application does not auto-launch; open it manually from your system menu. On first launch, an interactive onboarding wizard will appear (Next → Next → Finish).

## Execution Order & Commands

### Base (`scripts/base.sh`)

| # | Command | Description |
|---|---|---|
| 1 | `dnf install git` | Version control |
| 2 | `dnf install curl wget` | Download utilities |
| 3 | `dnf install unzip` | Archive extraction |
| 4 | `dnf install fzf` | Fuzzy finder (Ctrl+R, file search) |
| 5 | `dnf install ripgrep` | Fast code search (`rg`) |
| 6 | `dnf install bat` | Syntax-highlighted file viewer |
| 7 | `dnf install eza` | Modern `ls` with icons |
| 8 | `dnf install zoxide` | Smart `cd` with frecency |

### Terminal (`scripts/terminal.sh`)

| # | Command | Description |
|---|---|---|
| 9 | `dnf install zsh` | Zsh shell |
| 10 | `chsh -s /usr/bin/zsh` | Set Zsh as default shell |
| 11 | `install oh-my-zsh --unattended` | Shell framework |
| 12 | `git clone zsh-autosuggestions` | Fish-like suggestions |
| 13 | `git clone zsh-syntax-highlighting` | Command highlighting |
| 14 | `curl starship install.sh` | Cross-shell prompt |
| 15 | `cp dotfiles/.zshrc ~/.zshrc` | Deploy shell configuration |

### Dev (`scripts/dev.sh`)

| # | Command | Description |
|---|---|---|
| 16 | `curl lazygit release` + `install` | Terminal Git UI |
| 17 | `dnf install dotnet-sdk-10.0` | .NET 10 SDK |

### Containers (`scripts/containers.sh`)

| # | Command | Description |
|---|---|---|
| 18 | `dnf install podman` | Container engine |
| 19 | `dnf install podman-compose` | Legacy compose helper (fallback) |
| 20 | `dnf install podman-docker` | Docker CLI shim → maps `docker` to Podman |
| 21 | `systemctl --user enable --now podman.socket` | User socket for VS Code and SDK integrations |
| 22 | `dnf install docker-compose-plugin` (or manual binary fallback) | Modern `docker compose` subcommand |
| 23 | `flatpak install io.podman_desktop.PodmanDesktop` | Podman Desktop UI (only with `--ui`) |

## Container Stack Explained

```
Your command          What runs underneath
─────────────────── → ──────────────────────
docker ps             Podman (via podman-docker shim)
docker compose up     Docker Compose plugin → Podman socket
podman-compose up     podman-compose (legacy, still available)
```

## Productivity Summary

| Area | Tool | Benefit |
|---|---|---|
| Search | `ripgrep` + `fzf` | Instant code/file search |
| Navigation | `zoxide` | Jump to any directory by name |
| Readability | `bat` + `eza` | Better `cat` and `ls` |
| Git | `lazygit` + aliases | Full Git UI in the terminal |
| Prompt | `starship` | Context-aware, fast prompt |
| Containers | `podman` + `docker compose` | Docker-compatible, daemonless |
| Backend | `.NET SDK 10` | Build and run .NET apps |

## Re-running the Setup

All modules are idempotent — re-running `./setup.sh` is safe:
- `dnf install` skips already-installed packages
- `git clone` only runs if plugin directory does not exist
- `lazygit` / `dotnet` / `starship` install only if binary is absent
- `podman-docker` installs only if `docker` is not in PATH
- `docker compose` installs only if `docker compose version` fails
- `flatpak install` skips if already installed

