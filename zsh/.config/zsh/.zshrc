emulate sh
if [[ -f /app/share/Profile ]]; then
  . /app/share/Profile 
fi
umask 022
emulate zsh
export EDITOR='nvim'
export PATH="$PATH:$HOME/.tmux/"
export XDG_DATA_HOME="$HOME/.local/share/"

. "$HOME/.config/environments/hosts.sh" 
. "$HOME/.config/environments/paths.sh" 
. "$HOME/.config/environments/langs.sh" 
. "$HOME/.local/bin/env"
. "$HOME/.cargo/env"
. "$HOME/.aliases"
. ${ZDOTDIR:-~}/.antidote/antidote.zsh

antidote load

. ~/.fzf.zsh

DISABLE_AUTO_TITLE=true
export ZSH_AUTOSUGGEST_USE_ASYNC="true"
export ZSH_AUTOSUGGEST_MANUAL_REBIND=on
_zsh_autosuggest_bind_widgets

eval "$(~/.local/bin/mise activate zsh)"
autoload -Uz compinit && compinit

bindkey '^f' autosuggest-accept
VI_MODE_SET_CURSOR=true
VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true

. ${ZDOTDIR:-~}/.p10k.zsh

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
