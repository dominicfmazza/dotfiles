# bootstrap.sh: ZDOTDIR shim.
#
# An older install of these dotfiles exported ZDOTDIR=~/.config/zsh. Every
# zsh file now lives in $HOME. A shell that still carries the old ZDOTDIR
# would find no startup file here and run zsh-newuser-install, which shows a
# configurator menu instead of a prompt.
#
# zsh reads $ZDOTDIR/.zshenv before it chooses any other startup file, so
# this is the only place that can redirect such a shell.
#
# Delete this file once no session carries the old ZDOTDIR.

ZDOTDIR=$HOME
export ZDOTDIR

[[ -r $HOME/.zshenv ]] && source "$HOME/.zshenv"
[[ -o login && -r $HOME/.zprofile ]] && source "$HOME/.zprofile"
[[ -o interactive && -r $HOME/.zshrc ]] && source "$HOME/.zshrc"
