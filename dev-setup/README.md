# Dev Setup (Modular, Idempotent, Versionable)

This project provides a modular developer environment setup for Fedora/RHEL-based systems using `dnf`.

The current version keeps command logic exactly as defined in the scripts and focuses only on developer productivity:
- terminal workflow
- git workflow
- VS Code-ready tooling
- container tooling

No GPU tuning and no power mode configuration are included.

## Project Structure

```text
dev-setup/
├── setup.sh
├── scripts/
│   ├── base.sh
│   ├── terminal.sh
│   ├── dev.sh
│   ├── containers.sh
├── dotfiles/
│   └── .zshrc
```

## What Is Included

- Base CLI tools: `git`, `curl`, `wget`, `unzip`
- Productivity CLI tools: `fzf`, `ripgrep`, `bat`, `eza`, `zoxide`
- Terminal stack: `zsh`, Oh My Zsh, autosuggestions, syntax highlighting, `starship`
- Dev tools: `lazygit`, `.NET SDK 10`
- Containers: `podman`, `podman-compose`, `podman.socket`

## How To Run (Step by Step)

1. Clone your repository.
2. Enter the setup folder:
   ```bash
   cd dev-setup
   ```
3. Make scripts executable:
   ```bash
   chmod +x setup.sh scripts/*.sh
   ```
4. Run the setup:
   ```bash
   ./setup.sh
   ```
5. Restart session (`logout/login`) to apply shell defaults.

## Command Coverage Table

### Base

| Order | Command | Description |
|---|---|---|
| 1 | `dnf install git` | Version control |
| 2 | `dnf install curl wget` | Download tools |
| 3 | `dnf install unzip` | Archive extraction |
| 4 | `dnf install fzf` | Interactive fuzzy finder |
| 5 | `dnf install ripgrep` | Fast code/text search |
| 6 | `dnf install bat` | Better file viewer |
| 7 | `dnf install eza` | Modern `ls` replacement |
| 8 | `dnf install zoxide` | Smart directory navigation |

### Terminal

| Order | Command | Description |
|---|---|---|
| 9 | `dnf install zsh` | Zsh shell |
| 10 | `chsh` | Set default shell |
| 11 | `install oh-my-zsh` | Shell framework |
| 12 | `install plugins` | Suggestions + highlighting |
| 13 | `install starship` | Prompt customization |
| 14 | `.zshrc` | Terminal configuration |

### Dev

| Order | Command | Description |
|---|---|---|
| 15 | `install lazygit` | Terminal Git UI |
| 16 | `install dotnet-sdk-10.0` | .NET backend SDK |

### Containers

| Order | Command | Description |
|---|---|---|
| 17 | `install podman` | Container runtime |
| 18 | `install podman-compose` | Compose-like orchestration |
| 19 | `enable podman.socket` | User-level container socket |

## Exact Script Execution Flow

`setup.sh` runs the modules in this order:

1. `scripts/base.sh`
2. `scripts/terminal.sh`
3. `scripts/dev.sh`
4. `scripts/containers.sh`

## Productivity-Focused Technical Summary

This setup provides a practical and repeatable dev environment with:

- fast search and navigation (`ripgrep`, `fzf`, `zoxide`)
- improved terminal UX (`zsh`, plugins, `starship`)
- better command-line readability (`bat`, `eza`)
- faster Git workflows (`lazygit` + aliases)
- containerized workflows (`podman`, `podman-compose`)
- backend runtime support (`.NET SDK 10`)

It is organized as independent modules, easy to version in Git, and ready for iterative improvements in future versions.
