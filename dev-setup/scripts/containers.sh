#!/usr/bin/env bash
set -euo pipefail

# Optional: pass 'true' as first argument (via setup.sh --ui) to install Podman Desktop
INSTALL_UI=${1:-false}

echo "🐳 Configuring containers..."

# -----------------------------------------------------------------------------
# 1. Podman engine + legacy compose helper
# dnf is idempotent — safe to re-run; already-installed packages are skipped.
# -----------------------------------------------------------------------------
echo "[INFO] Installing Podman and podman-compose..."
sudo dnf install -y podman podman-compose

# -----------------------------------------------------------------------------
# 2. Docker CLI compatibility shim (podman-docker)
# Provides the 'docker' command backed by Podman, required by many dev tools.
# Guard ensures we don't reinstall if 'docker' already resolves in PATH.
# -----------------------------------------------------------------------------
if ! command -v docker &>/dev/null; then
  echo "[INFO] Installing podman-docker (Docker CLI compatibility)..."
  sudo dnf install -y podman-docker
else
  echo "[SKIP] docker already available: $(docker --version 2>&1 | head -1)"
fi

# -----------------------------------------------------------------------------
# 3. Podman socket — needed for VS Code, dev tools, and SDK integrations
# '|| true' prevents script abort if the user session has no systemd support.
# -----------------------------------------------------------------------------
echo "[INFO] Enabling podman.socket..."
systemctl --user enable --now podman.socket || true

# -----------------------------------------------------------------------------
# 4. Docker Compose plugin (modern 'docker compose' subcommand)
# Strategy:
#   a) Skip entirely if already functional
#   b) Try dnf (works on some Fedora versions)
#   c) Fallback: install binary directly to ~/.docker/cli-plugins (always works)
# Arch-aware: supports x86_64 and aarch64.
# -----------------------------------------------------------------------------
echo "[INFO] Checking docker compose plugin..."

if docker compose version &>/dev/null 2>&1; then
  echo "[SKIP] docker compose already installed: $(docker compose version)"
else
  echo "[INFO] Trying to install docker-compose-plugin via dnf..."

  if sudo dnf install -y docker-compose-plugin 2>/dev/null; then
    echo "[OK] docker compose installed via dnf"
  else
    echo "[WARN] dnf package not available — using manual binary install (fallback)..."

    ARCH=$(uname -m)
    case "$ARCH" in
      x86_64)  COMPOSE_ARCH="x86_64" ;;
      aarch64) COMPOSE_ARCH="aarch64" ;;
      *)
        echo "[ERROR] Unsupported architecture: $ARCH"
        exit 1
        ;;
    esac

    COMPOSE_DIR="$HOME/.docker/cli-plugins"
    mkdir -p "$COMPOSE_DIR"

    echo "[INFO] Downloading docker-compose binary for ${COMPOSE_ARCH}..."
    curl -fsSL \
      "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-${COMPOSE_ARCH}" \
      -o "$COMPOSE_DIR/docker-compose"

    chmod +x "$COMPOSE_DIR/docker-compose"
    echo "[OK] docker compose installed to $COMPOSE_DIR/docker-compose"
  fi
fi

# -----------------------------------------------------------------------------
# 5. Podman Desktop — optional graphical UI (only when --ui flag is passed)
# Installed via Flatpak. Does NOT auto-launch; opens onboarding on first manual run.
# Idempotent: flatpak skips if already installed.
# -----------------------------------------------------------------------------
if [ "$INSTALL_UI" = true ]; then
  echo "[INFO] Installing Podman Desktop via Flatpak..."

  if ! command -v flatpak &>/dev/null; then
    echo "[INFO] Flatpak not found — installing..."
    sudo dnf install -y flatpak
  fi

  flatpak install -y flathub io.podman_desktop.PodmanDesktop || true

  echo "[OK] Podman Desktop installed. Launch it manually when needed."
else
  echo "[SKIP] Podman Desktop not requested. Re-run with --ui to install it."
fi

echo "✅ Containers OK"