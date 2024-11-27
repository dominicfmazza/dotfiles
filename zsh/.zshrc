[[ "$TERM" == "xterm" ]] && export TERM=xterm-256color
# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# export NVM_LAZY_LOAD=true
ZSH_THEME="powerlevel10k/powerlevel10k" # set by `omz`
plugins=(
	zoxide
	direnv
	zsh-autosuggestions
	history-substring-search
)

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=5"
export ZSH_AUTOSUGGEST_USE_ASYNC="true"

source $ZSH/oh-my-zsh.sh

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#
export LANG=en_US.UTF-8
#
# # Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nvim'
else
  export EDITOR='nvim'
fi
#
source ~/.config/zsh/cpp.sh
source ~/.config/zsh/paths.sh
source ~/.config/zsh/hosts.sh
#
export ZSH_AUTOSUGGEST_MANUAL_REBIND=on
_zsh_autosuggest_bind_widgets

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

DISABLE_AUTO_TITLE=true

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

