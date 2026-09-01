# User specific environment and startup programs

export ZDOTDIR=$HOME/.config/zsh

export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
export XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}
export UV_CACHE_DIR=$XDG_CACHE_HOME/uv

# Host-specific values. bootstrap.sh seeds these files from
# install/templates/. They stay out of git.
[ -f "$XDG_CONFIG_HOME/environments/hosts.sh" ] && . "$XDG_CONFIG_HOME/environments/hosts.sh"
[ -f "$XDG_CONFIG_HOME/environments/paths.sh" ] && . "$XDG_CONFIG_HOME/environments/paths.sh"
[ -f "$XDG_CONFIG_HOME/environments/langs.sh" ] && . "$XDG_CONFIG_HOME/environments/langs.sh"

export PATH=$PATH:$HOME/.local/bin:$HOME/bin

[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
[ -f "$HOME/.aliases" ] && . "$HOME/.aliases"

# An older install used bob for Neovim. mise supplies it now, but keep the
# bob path working for a host that still has it.
if [[ -f "$XDG_DATA_HOME/bob/env/env.sh" ]]; then
    . "$XDG_DATA_HOME/bob/env/env.sh"
fi

export PATH="$XDG_DATA_HOME/mise/shims:$PATH"
