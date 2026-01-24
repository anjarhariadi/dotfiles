DISABLE_AUTO_UPDATE="true"
DISABLE_MAGIC_FUNCTIONS="true"
DISABLE_COMPFIX="true"

# Cache completions aggressively
autoload -Uz compinit
if [ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]; then
    compinit
else
    compinit -C
fi

export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

export ZSH="$HOME/.oh-my-zsh"

export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/Dev/SDK/flutter/bin
#export PATH=$PATH:$HOME/Dev/SDK/typst-x86_64-unknown-linux-musl

export JAVA_HOME=/home/alphaleonis/.jdks/ms-17.0.16
export PATH=$JAVA_HOME/bin:$PATH

eval "$(starship init zsh)"

#SH_THEME="robbyrussell"

plugins=(zsh-autosuggestions fast-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# Autosuggest settings
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="20"
ZSH_AUTOSUGGEST_USE_ASYNC=1

# User configuration
alias c=clear
alias e=exit
alias v=nvim

alias co="code . && exit"

alias venv-on="source ~/Dev/SDK/ds-venv/bin/activate"
alias themes="~/dotfiles/.config/starship-themes/select-starship-config.sh"

alias ga="git add ."
alias gs="git status"
alias lzd='lazydocker'
# eza (better `ls`)
# alias l="eza --icons"
# alias ls="eza --icons"
# alias ll="eza -lg --icons"
# alias la="eza -lag --icons"
# alias lt="eza -lTg --icons"
# alias lt1="eza -lTg --level=1 --icons"
# alias lt2="eza -lTg --level=2 --icons"
# alias lt3="eza -lTg --level=3 --icons"
# alias lta="eza -lTag --icons"
# alias lta1="eza -lTag --level=1 --icons"
# alias lta2="eza -lTag --level=2 --icons"
# alias lta3="eza -lTag --level=3 --icons"


# fnm
FNM_PATH="/home/alphaleonis/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="/home/alphaleonis/.local/share/fnm:$PATH"
  eval "`fnm env`"
fi
