#!/usr/bin/env bash

set -e

echo "🚀 Atualizando sistema..."
sudo dnf update -y

echo "📦 Instalando pacotes base..."
sudo dnf install -y \
  zsh git curl wget unzip \
  fzf ripgrep bat eza zoxide \
  podman podman-compose

echo "🐚 Configurando Zsh como shell padrão..."
if [ "$SHELL" != "/usr/bin/zsh" ]; then
  chsh -s /usr/bin/zsh $USER || true
fi

echo "📁 Instalando Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

echo "🔌 Instalando plugins Zsh..."
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
fi

echo "⭐ Instalando Starship..."
if ! command -v starship &> /dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

echo "📦 Instalando LazyGit..."
if ! command -v lazygit &> /dev/null; then
  LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '"tag_name": "v\K[^"]*')
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar xf lazygit.tar.gz lazygit
  sudo install lazygit /usr/local/bin
  rm -f lazygit lazygit.tar.gz
fi

echo "⚙️ Criando .zshrc..."
cat > ~/.zshrc <<'EOF'
export ZSH="$HOME/.oh-my-zsh"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY

autoload -Uz compinit
compinit
zstyle ':completion:*' menu select

bindkey '^I' autosuggest-accept

alias gs="git status"
alias ga="git add ."
alias gc="git commit -m"
alias gp="git push"

alias dc="podman-compose"
alias dcu="podman-compose up -d"
alias dcd="podman-compose down"

alias ls="eza --icons"
alias ll="eza -lah --icons"
alias cat="bat"
EOF

echo "✅ Setup concluído!"
echo "⚠️ Reinicie a sessão (logout/login)"