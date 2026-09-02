# .zshrc runs for an INTERACTIVE shell only.
#
# Every zsh file lives in $HOME. ZDOTDIR is not set on purpose: a ZDOTDIR
# moves where zsh looks for .zprofile and .zshrc, and setting it correctly
# requires a $HOME/.zshenv anyway. Keeping the files in $HOME removes that
# whole ordering trap.

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

# The zfunctions plugin defaults ZFUNCDIR to $XDG_CONFIG_HOME/zsh/functions.
# Every other zsh file sits in $HOME, so name the directory here instead of
# leaving a lone zsh folder under ~/.config.
export ZFUNCDIR=$HOME/.zfunctions

# Activate mise BEFORE antidote loads a plugin. A plugin such as the oh-my-zsh
# zoxide one probes for its binary at load time, and every tool lives behind
# the mise shims. Activating later makes that plugin print a false warning
# and skip its setup.
[[ -x ~/.local/bin/mise ]] && eval "$(~/.local/bin/mise activate zsh)"

for brew_prefix in /home/linuxbrew/.linuxbrew /opt/homebrew "$HOME/.linuxbrew"; do
  if [[ -x "$brew_prefix/bin/brew" ]]; then
    eval "$("$brew_prefix/bin/brew" shellenv zsh)"
    break
  fi
done
unset brew_prefix

[ -f ~/.antidote/antidote.zsh ] && . ~/.antidote/antidote.zsh
(( $+functions[antidote] )) && antidote load ~/.zsh_plugins.txt

(( $+commands[sk] )) && source =(sk --shell zsh --shell-bindings)

DISABLE_AUTO_TITLE=true
export ZSH_AUTOSUGGEST_USE_ASYNC="true"
export ZSH_AUTOSUGGEST_MANUAL_REBIND=on
(( $+functions[_zsh_autosuggest_bind_widgets] )) && _zsh_autosuggest_bind_widgets

# compinit writes a dump file. On a network home that write is slow, so
# .zshenv points ZSH_COMPDUMP at local disk when the home is remote.
autoload -Uz compinit && compinit -d "${ZSH_COMPDUMP:-$HOME/.zcompdump}"

bindkey '^f' autosuggest-accept
VI_MODE_SET_CURSOR=true
VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
[[ -f ~/.aliases ]] && source ~/.aliases

# oh-my-posh draws the prompt. Report a miss rather than falling back to the
# bare zsh default with no explanation, which looks like a broken shell.
if (( $+commands[oh-my-posh] )); then
  eval "$(oh-my-posh init zsh --config ~/.omp.yaml)"
else
  print -u2 "zsh: oh-my-posh is missing, so the prompt is a fallback."
  print -u2 "     Fix it with: mise install -y ubi:JanDeDobbeleer/oh-my-posh"
  # A readable prompt in the meantime: user, host, directory, and git branch.
  autoload -Uz vcs_info
  zstyle ':vcs_info:git:*' formats ' %b'
  precmd_functions+=(vcs_info)
  setopt prompt_subst
  PROMPT='%F{blue}%n@%m%f %F{cyan}%~%f%F{green}${vcs_info_msg_0_}%f %# '
fi
