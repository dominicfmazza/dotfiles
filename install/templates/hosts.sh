# Host-specific paths and identities. bootstrap.sh copies this file to
# ~/.config/environments/hosts.sh and never overwrites it.
# Edit the values. Keep secrets in ~/.env.json instead.

# Root of the Obsidian vault. nvim and the notes scripts read this.
export OBSIDIAN_VAULT_ROOT="$HOME/vaults"

# AWS profile and single sign-on endpoints. Leave unset on a personal host.
# export AWS_PROFILE=
# export AWS_DEFAULT_SSO_START_URL=
# export AWS_DEFAULT_SSO_REGION=
