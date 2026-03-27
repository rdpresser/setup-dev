# Dev Setup — V3 (Modular, Idempotent, Versionable)

Modular developer environment setup for Fedora/RHEL-based systems.
All scripts are idempotent and safe to re-run on fresh or already-configured machines.

Scope:
- Dev productivity stack: terminal, Git, containers, .NET SDK
- Optional NVIDIA GPU setup via dedicated standalone script and setup flags

Out of scope:
- Power mode tuning
- Energy profile automation

## Project Structure

```text
dev-setup/
├── setup.sh                  # Orchestrator — parses flags and runs modules in order
├── scripts/
│   ├── base.sh               # CLI productivity tools
│   ├── terminal.sh           # Zsh + Oh My Zsh + plugins + Starship + dotfile deploy
│   ├── dev.sh                # LazyGit + .NET SDK
│   ├── containers.sh         # Podman stack + Docker compatibility + optional UI
│   └── gpu.sh                # Standalone NVIDIA setup (profile-based, with install/undo/reset)
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
| Optional UI | Podman Desktop (Flatpak, via `--ui`) |
| GPU script | NVIDIA profile support (`alienware` implemented, `lenovo` reserved) |

## Setup Usage

```bash
# 1. Clone the repository
git clone https://github.com/rdpresser/setup-dev.git
cd setup-dev/dev-setup

# 2. Make scripts executable
chmod +x setup.sh scripts/*.sh

# 3a. Standard dev setup
./setup.sh

# 3b. Dev setup + Podman Desktop
./setup.sh --ui

# 3c. Dev setup + NVIDIA profile
./setup.sh --gpu-alienware

# 3d. Full setup (dev + UI + GPU)
./setup.sh --ui --gpu-alienware
```

`setup.sh` validates unknown arguments and exits with error for unsupported flags.

## Standalone GPU Script Usage

```bash
# Install/repair NVIDIA for Alienware profile
sudo bash scripts/gpu.sh alienware install

# Undo NVIDIA packages and managed config
sudo bash scripts/gpu.sh alienware undo

# Redo from scratch (undo + install)
sudo bash scripts/gpu.sh alienware reset
```

Supported profiles:
- `alienware`: implemented
- `lenovo`: reserved and intentionally returns an error until implemented

## Execution Order (Command Summary)

### Base (`scripts/base.sh`)

| # | Description | Command |
|---|---|---|
| 1 | Install base CLI | `sudo dnf install -y git curl wget unzip fzf ripgrep bat eza zoxide` |

### Terminal (`scripts/terminal.sh`)

| # | Description | Command |
|---|---|---|
| 2 | Install Zsh | `sudo dnf install -y zsh` |
| 3 | Set default shell | `chsh -s /usr/bin/zsh $USER` |
| 4 | Install Oh My Zsh | `sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended` |
| 5 | Install plugins | `git clone ... zsh-autosuggestions` and `git clone ... zsh-syntax-highlighting` |
| 6 | Install Starship | `curl -sS https://starship.rs/install.sh | sh -s -- -y` |
| 7 | Deploy shell config | `cp dotfiles/.zshrc ~/.zshrc` |

### Dev (`scripts/dev.sh`)

| # | Description | Command |
|---|---|---|
| 8 | Install LazyGit | `curl` + `tar` + `sudo install` |
| 9 | Install .NET SDK 10 | `sudo dnf install -y dotnet-sdk-10.0` |

### Containers (`scripts/containers.sh`)

| # | Description | Command |
|---|---|---|
| 10 | Install Podman stack | `sudo dnf install -y podman podman-compose` |
| 11 | Install Docker CLI shim if missing | `sudo dnf install -y podman-docker` |
| 12 | Enable Podman socket | `systemctl --user enable --now podman.socket` |
| 13 | Install Docker Compose plugin | `sudo dnf install -y docker-compose-plugin` |
| 14 | Compose fallback if dnf fails | `curl ... -o ~/.docker/cli-plugins/docker-compose && chmod +x ...` |
| 15 | Optional Podman Desktop | `flatpak install -y flathub io.podman_desktop.PodmanDesktop` |

### GPU Optional (`scripts/gpu.sh`)

| # | Description | Command |
|---|---|---|
| 16 | Add RPM Fusion if missing | `dnf install -y rpmfusion-free-release ... rpmfusion-nonfree-release ...` |
| 17 | Refresh packages | `dnf upgrade --refresh -y` |
| 18 | Install NVIDIA driver stack if missing | `dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda` |
| 19 | Ensure build dependencies | `dnf install -y kernel-devel kernel-headers gcc make dkms` |
| 20 | Rebuild modules/initramfs | `akmods --force` and `dracut --force` |
| 21 | Write PRIME config (managed) | `/etc/modprobe.d/nvidia-prime.conf` |

## Re-run and Idempotency Notes

Re-running is expected and supported:
- `dnf install -y` skips installed packages
- plugin clones run only when directories are missing
- GPU script checks managed files and installed packages before writing/installing
- Compose installation checks `docker compose version` first
- Podman Desktop install is optional and only runs with `--ui`

GPU script supports operational modes:
- `install`: only apply what is missing
- `undo`: remove managed NVIDIA stack and config
- `reset`: undo then install
