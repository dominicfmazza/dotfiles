. /app/share/Profile
umask 022
export EDITOR='nvim'
export PATH="$PATH:$HOME/.tmux/"
export XDG_DATA_HOME="$HOME/.local/share/"

. "$HOME/.config/environments/hosts.sh" 
. "$HOME/.config/environments/paths.sh" 
. "$HOME/.config/environments/langs.sh" 
. "$HOME/.local/bin/env"
. "$HOME/.cargo/env"
. "$HOME/.aliases"
