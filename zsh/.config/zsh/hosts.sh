export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

if [ "$HOSTNAME" = masterchief-svr02 ]; then
	export XDG_CACHE_HOME="/disk01/users/dom/.cache/"
	export XDG_DATA_HOME="/disk01/users/dom/.local/share/"
	alias ij="/disk01/users/dom/external_source/Fiji.app/ImageJ-linux64"
fi
