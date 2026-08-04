#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
config_dir="${XDG_CONFIG_HOME:-"$HOME/.config"}/git-config"
shared_config="$config_dir/shared.gitconfig"
local_config="$config_dir/local.gitconfig"

mkdir -p -- "$config_dir"

if [[ -e "$shared_config" && ! -L "$shared_config" ]]; then
	printf 'Refusing to replace existing non-symlink: %s\n' "$shared_config" >&2
	exit 1
fi

ln -sfn -- "$repo_dir/gitconfig" "$shared_config"

if [[ ! -e "$local_config" ]]; then
	umask 077
	cp -- "$repo_dir/local.gitconfig.example" "$local_config"
	chmod 600 -- "$local_config"
	printf 'Created %s; set your name and email before committing.\n' "$local_config"
fi

if ! git config --global --get-all include.path 2>/dev/null |
	grep -Fx -- "$shared_config" >/dev/null; then
	git config --global --add include.path "$shared_config"
fi

printf 'Shared Git configuration enabled from %s\n' "$shared_config"
