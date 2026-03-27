#!/usr/bin/env bash
set -euo pipefail

# Parse optional flags
# --ui            : also install Podman Desktop
# --gpu-alienware : run NVIDIA setup profile for Alienware
# --gpu-lenovo    : reserved profile (currently not implemented in gpu.sh)
INSTALL_UI=false
GPU_PROFILE=""

for arg in "$@"; do
  case $arg in
    --ui)
      INSTALL_UI=true
      ;;
    --gpu-alienware)
      GPU_PROFILE="alienware"
      ;;
    --gpu-lenovo)
      GPU_PROFILE="lenovo"
      ;;
    --help|-h)
      echo "Usage: ./setup.sh [--ui] [--gpu-alienware|--gpu-lenovo]"
      exit 0
      ;;
    *)
      echo "[ERROR] Invalid argument: $arg"
      echo "Usage: ./setup.sh [--ui] [--gpu-alienware|--gpu-lenovo]"
      exit 1
      ;;
  esac
done

echo "🚀 Starting dev environment setup..."

bash scripts/base.sh
bash scripts/terminal.sh
bash scripts/dev.sh
bash scripts/containers.sh "$INSTALL_UI"

if [ -n "$GPU_PROFILE" ]; then
  echo "🎮 Running GPU setup for profile: $GPU_PROFILE"
  sudo bash scripts/gpu.sh "$GPU_PROFILE" install
else
  echo "[SKIP] GPU setup not requested"
fi

echo ""
echo "✅ Setup complete!"
echo "👉 Restart your session (logout/login) to apply shell changes."