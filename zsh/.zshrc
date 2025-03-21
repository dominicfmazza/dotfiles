ZDOTDIR=$HOME/.config/zsh/
[[ "$TERM" == "xterm" ]] && export TERM=xterm-256color

export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export EDITOR='nvim'


source_if_exists() {
  if [ -f "$1" ]; then
      source "$1"
  fi
}

source_if_exists "$HOME/.config/environment/hosts.sh" 
source_if_exists "$HOME/.config/environment/paths.sh" 
source_if_exists "$HOME/.config/environment/langs.sh" 
source_if_exists "$HOME/.local/bin/env"


check_brew() { 
    if [ -f $1/bin/brew ]; then
        eval "$($1/bin/brew shellenv)"
    fi
}

check_brew /opt/homebrew
check_brew "/usr/local/homebrew"
check_brew /home/linuxbrew/.linuxbrew

if [ -n $GOPATH ]; then
    export PATH=$PATH:$GOPATH/bin
fi 

source_if_exists ${ZDOTDIR:-~}/.antidote/antidote.zsh

antidote load

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


source_if_exists ~/.fzf.zsh
source_if_exists ~/.p10k.zsh

DISABLE_AUTO_TITLE=true

source_if_exists $HOME/.cargo/env

zstyle :omz:plugins:ssh-agent lazy yes

autoload -Uz promptinit && promptinit && prompt powerlevel10k

export ZSH_AUTOSUGGEST_USE_ASYNC="true"
export ZSH_AUTOSUGGEST_MANUAL_REBIND=on
_zsh_autosuggest_bind_widgets

. "$HOME/.local/share//../bin/env"
