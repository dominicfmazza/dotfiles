ZDOTDIR=$HOME/.config/zsh
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

if [ -n $GOPATH ]; then
    export PATH=$PATH:$GOPATH/bin
fi 

source_if_exists ${ZDOTDIR:-~}/.antidote/antidote.zsh

antidote load

source_if_exists ~/.fzf.zsh
source_if_exists ~/.p10k.zsh
DISABLE_AUTO_TITLE=true
source_if_exists $HOME/.cargo/env
zstyle :omz:plugins:ssh-agent lazy yes
autoload -Uz promptinit && promptinit && prompt powerlevel10k
export ZSH_AUTOSUGGEST_USE_ASYNC="true"
export ZSH_AUTOSUGGEST_MANUAL_REBIND=on
_zsh_autosuggest_bind_widgets
source_if_exists "$HOME/.local/share/bin/env"
export PATH="$HOME/.local/bin:$HOME/.tmux/:$PATH"
export XDG_DATA_HOME="$HOME/.local/share/"
eval "$(~/.local/bin/mise activate zsh)"
source_if_exists "$HOME/.aliases"

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
