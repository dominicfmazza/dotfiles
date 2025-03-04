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

if [ -f /opt/homebrew/bin/brew ]; then
    brew_prefix=/opt/homebrew
elif [ -f "/usr/local/homebrew/bin/brew" ]; then
    brew_prefix="/usr/local/homebrew"
elif [ -f /home/linuxbrew/bin/brew ]; then
    brew_prefix=/home/linuxbrew
fi

if [ -n $brew_prefix ]; then
    eval "$($brew_prefix/bin/brew shellenv)"
fi

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
