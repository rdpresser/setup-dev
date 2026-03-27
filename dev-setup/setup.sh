#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Iniciando setup de ambiente dev..."

bash scripts/base.sh
bash scripts/terminal.sh
bash scripts/dev.sh
bash scripts/containers.sh

echo ""
echo "✅ Setup finalizado!"
echo "👉 Reinicie a sessão (logout/login)"