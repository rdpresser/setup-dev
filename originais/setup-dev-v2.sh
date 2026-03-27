#!/usr/bin/env bash

# =============================================================================
# setup-dev-v2.sh — Configuração de ambiente de desenvolvimento (sandbox)
# Idempotente: pode ser executado múltiplas vezes sem efeitos colaterais.
# Testado em: Fedora / RHEL-based distros com dnf
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Utilitários de log
# -----------------------------------------------------------------------------
info()    { echo "[INFO]  $*"; }
success() { echo "[OK]    $*"; }
skip()    { echo "[SKIP]  $*"; }
warn()    { echo "[WARN]  $*"; }
section() { echo ""; echo "========== $* =========="; }

# -----------------------------------------------------------------------------
# Detecção de arquitetura (suporte a x86_64 e aarch64/ARM)
# -----------------------------------------------------------------------------
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  ARCH_LABEL="x86_64" ;;
  aarch64) ARCH_LABEL="arm64"  ;;
  *)
    warn "Arquitetura '$ARCH' não testada. Alguns downloads podem falhar."
    ARCH_LABEL="$ARCH"
    ;;
esac
info "Arquitetura detectada: $ARCH ($ARCH_LABEL)"

# =============================================================================
# 1. ATUALIZAÇÃO DO SISTEMA
# dnf update é idempotente — não faz nada se o sistema já está atualizado.
# =============================================================================
section "Atualizando sistema"
info "Executando dnf update..."
sudo dnf update -y
success "Sistema atualizado."

# =============================================================================
# 2. PACOTES BASE
# dnf install -y ignora pacotes já instalados, portanto é idempotente.
# =============================================================================
section "Instalando pacotes base"
info "Instalando: zsh git curl wget unzip fzf ripgrep bat eza zoxide podman podman-compose"
sudo dnf install -y \
  zsh git curl wget unzip \
  fzf ripgrep bat eza zoxide \
  podman podman-compose
success "Pacotes base instalados."

# =============================================================================
# 3. ZSH COMO SHELL PADRÃO
# Verifica o shell atual antes de tentar mudar, evitando chamada desnecessária
# ao chsh. O '|| true' garante que um erro não interrompa o script.
# =============================================================================
section "Configurando Zsh como shell padrão"
if [ "$SHELL" != "/usr/bin/zsh" ]; then
  info "Shell atual é '$SHELL'. Alterando para /usr/bin/zsh..."
  chsh -s /usr/bin/zsh "$USER" || warn "Não foi possível alterar o shell. Faça manualmente: chsh -s /usr/bin/zsh"
else
  skip "Zsh já é o shell padrão."
fi

# =============================================================================
# 4. OH MY ZSH
# Instalado apenas se o diretório ~/.oh-my-zsh ainda não existir.
# --unattended evita interações e não sobrescreve o .zshrc no final.
# =============================================================================
section "Instalando Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  info "Instalando Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  success "Oh My Zsh instalado."
else
  skip "Oh My Zsh já está instalado em $HOME/.oh-my-zsh."
fi

# =============================================================================
# 5. PLUGINS DO ZSH
# Cada plugin é clonado apenas se o diretório correspondente não existir.
# =============================================================================
section "Instalando plugins Zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  info "Clonando zsh-autosuggestions..."
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  success "zsh-autosuggestions instalado."
else
  skip "zsh-autosuggestions já existe."
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  info "Clonando zsh-syntax-highlighting..."
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  success "zsh-syntax-highlighting instalado."
else
  skip "zsh-syntax-highlighting já existe."
fi

# =============================================================================
# 6. STARSHIP PROMPT
# Instalado via script oficial apenas se o binário ainda não estiver em PATH.
# '-y' aceita os prompts automaticamente.
# =============================================================================
section "Instalando Starship"
if ! command -v starship &>/dev/null; then
  info "Instalando Starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y
  success "Starship instalado."
else
  skip "Starship já está instalado: $(starship --version)."
fi

# =============================================================================
# 7. LAZYGIT
# Detecta a última versão via API do GitHub, baixa o tarball correto para
# a arquitetura atual, instala e remove os arquivos temporários.
# Instalado apenas se o binário ainda não estiver disponível.
# =============================================================================
section "Instalando LazyGit"
if ! command -v lazygit &>/dev/null; then
  info "Buscando última versão do LazyGit na API do GitHub..."
  LAZYGIT_VERSION=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
    | grep -Po '"tag_name": "v\K[^"]*')

  if [ -z "$LAZYGIT_VERSION" ]; then
    warn "Não foi possível obter a versão do LazyGit. Pulando instalação."
  else
    info "Baixando LazyGit v${LAZYGIT_VERSION} para ${ARCH_LABEL}..."
    LAZYGIT_URL="https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_${ARCH_LABEL}.tar.gz"
    curl -fsSLo lazygit.tar.gz "$LAZYGIT_URL"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm -f lazygit lazygit.tar.gz
    success "LazyGit v${LAZYGIT_VERSION} instalado."
  fi
else
  skip "LazyGit já está instalado: $(lazygit --version 2>&1 | head -1)."
fi

# =============================================================================
# 8. CONFIGURAÇÃO DO .zshrc
# Usa um arquivo marcador (~/.zshrc.setup-managed) para detectar se o .zshrc
# já foi gerado por este script. Isso garante:
#   - Primeira execução: cria o .zshrc
#   - Execuções seguintes: não sobrescreve (preserva personalizações do usuário)
#   - Re-geração forçada: delete ~/.zshrc.setup-managed e rode novamente
#
# NOTA sobre bindkey: evitado o uso de ^I (Tab) para autosuggest-accept,
# pois conflita com o menu de autocompletar do compinit. Usando → (End) em vez.
# =============================================================================
section "Configurando .zshrc"
ZSHRC_MARKER="$HOME/.zshrc.setup-managed"

if [ ! -f "$ZSHRC_MARKER" ]; then
  info "Gerando ~/.zshrc..."

  # Faz backup se já existir um .zshrc (ex: criado pelo Oh My Zsh)
  if [ -f "$HOME/.zshrc" ]; then
    BACKUP="$HOME/.zshrc.bak.$(date +%Y%m%d_%H%M%S)"
    info "Backup do .zshrc existente em: $BACKUP"
    cp "$HOME/.zshrc" "$BACKUP"
  fi

  cat > "$HOME/.zshrc" <<'EOF'
# =============================================================================
# .zshrc — gerado por setup-dev-v2.sh
# Para regenerar, apague ~/.zshrc.setup-managed e execute o script novamente.
# =============================================================================

export ZSH="$HOME/.oh-my-zsh"

# Plugins carregados pelo Oh My Zsh
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source "$ZSH/oh-my-zsh.sh"

# Starship como prompt
eval "$(starship init zsh)"

# Zoxide como substituto inteligente de cd
eval "$(zoxide init zsh)"

# fzf — keybindings e autocompletar (instalado via dnf, sem ~/.fzf.zsh)
# Ativa keybindings do fzf se o arquivo de sistema estiver disponível
if [ -f /usr/share/fzf/shell/key-bindings.zsh ]; then
  source /usr/share/fzf/shell/key-bindings.zsh
fi
if [ -f /usr/share/zsh/site-functions/_fzf ]; then
  source /usr/share/zsh/site-functions/_fzf
fi
# Fallback para instalação via ~/.fzf (método manual)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Histórico
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY

# Autocompletar
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select

# Autosuggest: aceitar com → (End) — não conflita com Tab (^I) do compinit
bindkey '\e[F' autosuggest-accept   # End (xterm)
bindkey '\eOF' autosuggest-accept   # End (vt100)

# Aliases — Git
alias gs="git status"
alias ga="git add ."
alias gc="git commit -m"
alias gp="git push"

# Aliases — Podman / Compose
alias dc="podman-compose"
alias dcu="podman-compose up -d"
alias dcd="podman-compose down"

# Aliases — Ferramentas modernas
alias ls="eza --icons"
alias ll="eza -lah --icons"
alias cat="bat"
EOF

  # Cria o marcador para evitar sobrescrita em próximas execuções
  date > "$ZSHRC_MARKER"
  success "~/.zshrc gerado com sucesso."
else
  skip "~/.zshrc já foi configurado por este script (encontrado: $ZSHRC_MARKER)."
  info  "Para regenerar, apague '$ZSHRC_MARKER' e execute novamente."
fi

# =============================================================================
# CONCLUSÃO
# =============================================================================
section "Setup concluído"
success "Ambiente configurado com sucesso!"
echo ""
info "Próximos passos:"
echo "  1. Faça logout e login novamente (ou abra um novo terminal) para aplicar o Zsh."
echo "  2. Verifique o shell ativo com: echo \$SHELL"
echo "  3. Para reconfigurar o .zshrc, apague ~/.zshrc.setup-managed e execute este script novamente."
