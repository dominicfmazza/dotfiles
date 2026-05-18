# User specific environment and startup programs

export ZDOTDIR=$HOME/.config/zsh 

if [[ -f "$HOME/.local/share/bob/env/env.sh" ]]; then
    . "$HOME/.local/share/bob/env/env.sh"
fi

export XDG_DATA_HOME=$HOME/.local/share
export XDG_CACHE_HOME=$HOME/.cache
export XDG_STATE_HOME=$HOME/.local/state
export UV_CACHE_DIR=$HOME/.cache/uv

[ -f "$HOME/.config/environments/hosts.sh"  ] && . "$HOME/.config/environments/hosts.sh" 
[ -f "$HOME/.config/environments/paths.sh"  ] && . "$HOME/.config/environments/paths.sh" 
[ -f "$HOME/.config/environments/langs.sh"  ] && . "$HOME/.config/environments/langs.sh" 

export PATH=$PATH:$HOME/.local/bin:$HOME/bin

[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
[ -f "$HOME/.aliases" ] && . "$HOME/.aliases"

export PATH="$HOME/.local/share/mise/shims:$PATH"

