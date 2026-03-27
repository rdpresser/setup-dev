export ZSH="$HOME/.oh-my-zsh"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

# FZF
if [ -f /usr/share/fzf/shell/key-bindings.zsh ]; then
  source /usr/share/fzf/shell/key-bindings.zsh
fi

# Histórico
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY

# Autocomplete
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select

# Autosuggest (sem quebrar TAB)
bindkey '\e[F' autosuggest-accept
bindkey '\eOF' autosuggest-accept

# Aliases
alias gs="git status"
alias ga="git add ."
alias gc="git commit -m"
alias gp="git push"

# Container aliases use 'docker compose' (backed by Podman via podman-docker)
# podman-compose remains installed as a fallback if needed directly
alias dc="docker compose"
alias dcu="docker compose up -d"
alias dcd="docker compose down"

alias ls="eza --icons"
alias ll="eza -lah --icons"
alias cat="bat"