emulate sh
if [[ -f /app/share/Profile ]]; then
  . /app/share/Profile 
fi
umask 022

stty erase "^?"
emulate zsh
export PATH="$PATH:$HOME/.tmux/"
export MANPAGER='zsh -l -c nvrt +Man!'
export EDITOR='zsh -l -c nvrt'
export NPM_PACKAGES="${HOME}/.npm-packages"
export PATH="$NPM_PACKAGES/bin:$PATH"

[ -f "$HOME/.config/environments/hosts.sh"  ] && . "$HOME/.config/environments/hosts.sh" 
[ -f "$HOME/.config/environments/paths.sh"  ] && . "$HOME/.config/environments/paths.sh" 
[ -f "$HOME/.config/environments/langs.sh"  ] && . "$HOME/.config/environments/langs.sh" 

if [ -d $XDG_BASE_DIRECTORY ]; then 
	export XDG_DATA_HOME=$XDG_BASE_DIRECTORY/.local/share
	export XDG_CACHE_HOME=$XDG_BASE_DIRECTORY/.cache
	export XDG_STATE_HOME=$XDG_BASE_DIRECTORY/.local/state
	export UV_CACHE_DIR=$XDG_BASE_DIRECTORY/.cache/uv
	mkdir -p $XDG_DATA_HOME
	mkdir -p $XDG_CACHE_HOME
	mkdir -p $XDG_STATE_HOME
fi

eval "$(~/.local/bin/mise activate zsh)"

[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
[ -f "$HOME/.aliases" ] && . "$HOME/.aliases"
[ -f ${ZDOTDIR:-~}/.antidote/antidote.zsh ] && . ${ZDOTDIR:-~}/.antidote/antidote.zsh


antidote load

[ -f ~/.fzf.zsh ] && . ~/.fzf.zsh

DISABLE_AUTO_TITLE=true
export ZSH_AUTOSUGGEST_USE_ASYNC="true"
export ZSH_AUTOSUGGEST_MANUAL_REBIND=on
_zsh_autosuggest_bind_widgets

autoload -Uz compinit && compinit

bindkey '^f' autosuggest-accept
VI_MODE_SET_CURSOR=true
VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true


eval "$(oh-my-posh init zsh --config ~/.omp.yaml)"
