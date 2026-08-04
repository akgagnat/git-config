#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<'USAGE'
Usage: install.sh [--uninstall] [--help]

  (no options)  Link the shared Git configuration and register it as a global
                include, creating a local.gitconfig for identity if absent.
  --uninstall   Remove the global include and the shared symlink. The local
                configuration is kept, since it holds your identity.
USAGE
}

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
config_dir="${XDG_CONFIG_HOME:-"$HOME/.config"}/git-config"
shared_config="$config_dir/shared.gitconfig"
local_config="$config_dir/local.gitconfig"

action=install
case "${1-}" in
	--uninstall) action=uninstall ;;
	--help | -h)
		usage
		exit 0
		;;
	'') ;;
	*)
		printf 'Unknown option: %s\n\n' "$1" >&2
		usage >&2
		exit 2
		;;
esac

if ! command -v git >/dev/null 2>&1; then
	printf 'git is required but was not found on PATH.\n' >&2
	exit 1
fi

has_global_include() {
	git config --global --get-all include.path 2>/dev/null |
		grep -Fxq -- "$shared_config"
}

if [[ $action == uninstall ]]; then
	if has_global_include; then
		git config --global --unset-all include.path "$(printf '^%s$' "${shared_config//./\\.}")"
	fi

	if [[ -L $shared_config ]]; then
		rm -f -- "$shared_config"
	fi

	printf 'Shared Git configuration removed. Kept %s\n' "$local_config"
	exit 0
fi

mkdir -p -- "$config_dir"

if [[ -e $shared_config && ! -L $shared_config ]]; then
	printf 'Refusing to replace existing non-symlink: %s\n' "$shared_config" >&2
	exit 1
fi

ln -sfn -- "$repo_dir/gitconfig" "$shared_config"

if [[ ! -e $local_config ]]; then
	umask 077
	cp -- "$repo_dir/local.gitconfig.example" "$local_config"
	chmod 600 "$local_config"
	printf 'Created %s. Edit it to set your name and email before committing.\n' "$local_config"
fi

if ! has_global_include; then
	git config --global --add include.path "$shared_config"
fi

printf 'Shared Git configuration enabled from %s\n' "$shared_config"
