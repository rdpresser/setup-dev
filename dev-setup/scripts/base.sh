#!/usr/bin/env bash
set -euo pipefail

echo "📦 Instalando base..."

sudo dnf install -y \
  git curl wget unzip \
  fzf ripgrep bat eza zoxide

echo "✅ Base OK"