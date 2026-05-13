export ZDOTDIR=$HOME/.config/zsh 

eval "$(~/.local/bin/mise activate zsh)"

if [[ -f "$HOME/.local/share/bob/env/env.sh" ]]; then
    . "$HOME/.local/share/bob/env/env.sh"
fi
