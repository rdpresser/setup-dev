#!/usr/bin/env bash
set -euo pipefail

# Parse optional flags
# --ui   : also install Podman Desktop (requires Flatpak, opens graphical onboarding on first launch)
INSTALL_UI=false

for arg in "$@"; do
  case $arg in
    --ui)
      INSTALL_UI=true
      ;;
  esac
done

echo "🚀 Starting dev environment setup..."

bash scripts/base.sh
bash scripts/terminal.sh
bash scripts/dev.sh
bash scripts/containers.sh "$INSTALL_UI"

echo ""
echo "✅ Setup complete!"
echo "👉 Restart your session (logout/login) to apply shell changes."