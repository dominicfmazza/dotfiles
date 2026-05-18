export PATH="$PATH:$HOME/.tmux/"
export MANPAGER='zsh -l -c nvrt +Man!'
export EDITOR='zsh -l -c nvr'
export NPM_PACKAGES="${HOME}/.npm-packages"
export PATH="$NPM_PACKAGES/bin:$PATH"

[ -f ${ZDOTDIR:-~}/.antidote/antidote.zsh ] && . ${ZDOTDIR:-~}/.antidote/antidote.zsh

antidote load ${ZDOTDIR:-$HOME}/.zsh_plugins.txt

source =(sk --shell zsh --shell-bindings)

DISABLE_AUTO_TITLE=true
export ZSH_AUTOSUGGEST_USE_ASYNC="true"
export ZSH_AUTOSUGGEST_MANUAL_REBIND=on
_zsh_autosuggest_bind_widgets

autoload -Uz compinit && compinit

bindkey '^f' autosuggest-accept
VI_MODE_SET_CURSOR=true
VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
[[ -f ~/.aliases ]] && source ~/.aliases


eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"

eval "$(~/.local/bin/mise activate zsh)"

eval "$(oh-my-posh init zsh --config ~/.omp.yaml)"
