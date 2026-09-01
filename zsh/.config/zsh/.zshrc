# nvr talks to a running Neovim server. Fall back to plain nvim when the
# host has no nvr, so a bare host still gets a working editor.
if (( $+commands[nvr] )); then
  export EDITOR='zsh -l -c nvr'
  export MANPAGER='zsh -l -c nvrt +Man!'
elif (( $+commands[nvim] )); then
  export EDITOR=nvim
  export MANPAGER='nvim +Man!'
fi
export NPM_PACKAGES="${HOME}/.npm-packages"
export PATH="$NPM_PACKAGES/bin:$PATH"

[ -f ${ZDOTDIR:-~}/.antidote/antidote.zsh ] && . ${ZDOTDIR:-~}/.antidote/antidote.zsh

antidote load ${ZDOTDIR:-$HOME}/.zsh_plugins.txt

(( $+commands[sk] )) && source =(sk --shell zsh --shell-bindings)

DISABLE_AUTO_TITLE=true
export ZSH_AUTOSUGGEST_USE_ASYNC="true"
export ZSH_AUTOSUGGEST_MANUAL_REBIND=on
(( $+functions[_zsh_autosuggest_bind_widgets] )) && _zsh_autosuggest_bind_widgets

autoload -Uz compinit && compinit

bindkey '^f' autosuggest-accept
VI_MODE_SET_CURSOR=true
VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
[[ -f ~/.aliases ]] && source ~/.aliases

for brew_prefix in /home/linuxbrew/.linuxbrew /opt/homebrew "$HOME/.linuxbrew"; do
  if [[ -x "$brew_prefix/bin/brew" ]]; then
    eval "$("$brew_prefix/bin/brew" shellenv zsh)"
    break
  fi
done
unset brew_prefix

[[ -x ~/.local/bin/mise ]] && eval "$(~/.local/bin/mise activate zsh)"

(( $+commands[oh-my-posh] )) && eval "$(oh-my-posh init zsh --config ~/.omp.yaml)"
