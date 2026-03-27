#!/usr/bin/env bash
set -euo pipefail

echo "🐳 Configurando containers..."

sudo dnf install -y podman podman-compose

# Socket
systemctl --user enable --now podman.socket || true

echo "✅ Containers OK"