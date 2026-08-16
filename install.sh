#!/bin/sh
# POSIX sh on purpose: this script is meant to survive `curl ... | sh`, where
# the interpreter is whatever /bin/sh happens to be.
set -eu

repo_url=${GIT_CONFIG_REPO_URL:-https://github.com/akgagnat/git-config.git}
repo_ref=${GIT_CONFIG_REPO_REF:-main}
clone_dir=${GIT_CONFIG_CLONE_DIR:-"${XDG_DATA_HOME:-$HOME/.local/share}/git-config"}

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/git-config"
shared_config="$config_dir/shared.gitconfig"
local_config="$config_dir/local.gitconfig"

action=install
prompt=auto
user_name=${GIT_CONFIG_NAME:-}
user_email=${GIT_CONFIG_EMAIL:-}

usage() {
	cat <<'USAGE'
Usage: install.sh [options]

  (no options)     Link the shared Git configuration, register it as a global
                   include, and set your identity in local.gitconfig. When run
                   outside a checkout, the repository is cloned first.
  --name NAME      Use NAME as user.name instead of asking.
  --email EMAIL    Use EMAIL as user.email instead of asking.
  --no-prompt      Never ask; keep whatever identity is already configured.
  --ref REF        Branch or tag to clone when bootstrapping (default: main).
  --uninstall      Remove the global include and the shared symlink. The local
                   configuration is kept, since it holds your identity.
  --help, -h       Show this help.

Environment: GIT_CONFIG_NAME, GIT_CONFIG_EMAIL, GIT_CONFIG_REPO_URL,
GIT_CONFIG_REPO_REF, GIT_CONFIG_CLONE_DIR.
USAGE
}

die() {
	printf '%s\n' "$1" >&2
	exit "${2:-1}"
}

need_value() {
	[ "$1" -gt 1 ] || die "Option $2 requires a value." 2
}

while [ $# -gt 0 ]; do
	case $1 in
	--uninstall) action=uninstall ;;
	--no-prompt) prompt=never ;;
	--name)
		need_value $# "$1"
		shift
		user_name=$1
		;;
	--name=*) user_name=${1#--name=} ;;
	--email)
		need_value $# "$1"
		shift
		user_email=$1
		;;
	--email=*) user_email=${1#--email=} ;;
	--ref)
		need_value $# "$1"
		shift
		repo_ref=$1
		;;
	--ref=*) repo_ref=${1#--ref=} ;;
	--help | -h)
		usage
		exit 0
		;;
	*)
		printf 'Unknown option: %s\n\n' "$1" >&2
		usage >&2
		exit 2
		;;
	esac
	shift
done

command -v git >/dev/null 2>&1 ||
	die 'git is required but was not found on PATH.'

valid_email() {
	case $1 in
	*[!-A-Za-z0-9_.+@]* | @* | *@) return 1 ;;
	*@*.*) return 0 ;;
	*) return 1 ;;
	esac
}

if [ -n "$user_email" ] && ! valid_email "$user_email"; then
	die "Not a valid email address: $user_email"
fi

# Escape a literal string for use as a basic regular expression.
escape_regex() {
	printf '%s' "$1" | sed 's/[][\\.^$*]/\\&/g'
}

has_global_include() {
	git config --global --get-all include.path 2>/dev/null |
		grep -Fxq -- "$shared_config"
}

if [ "$action" = uninstall ]; then
	if has_global_include; then
		git config --global --unset-all include.path \
			"^$(escape_regex "$shared_config")\$"
	fi

	[ ! -L "$shared_config" ] || rm -f -- "$shared_config"

	printf 'Shared Git configuration removed. Kept %s\n' "$local_config"
	[ ! -d "$clone_dir" ] ||
		printf 'The checkout in %s was left in place.\n' "$clone_dir"
	exit 0
fi

# Locate the checkout this script belongs to. When the script is piped from the
# network there is no such checkout, so clone one to a stable location.
repo_dir=
if [ -r "$0" ]; then
	script_dir=$(unset CDPATH && cd -- "$(dirname -- "$0")" && pwd -P) ||
		script_dir=
	[ ! -f "$script_dir/gitconfig" ] || repo_dir=$script_dir
fi

if [ -z "$repo_dir" ]; then
	if [ -d "$clone_dir/.git" ]; then
		if [ -n "$(git -C "$clone_dir" status --porcelain)" ]; then
			printf 'Using %s as-is; it has uncommitted changes.\n' "$clone_dir"
		else
			printf 'Updating %s\n' "$clone_dir"
			git -C "$clone_dir" fetch --quiet --depth 1 origin "$repo_ref"
			git -C "$clone_dir" checkout --quiet -B "$repo_ref" FETCH_HEAD
		fi
	else
		printf 'Cloning %s into %s\n' "$repo_url" "$clone_dir"
		mkdir -p -- "$(dirname -- "$clone_dir")"
		git clone --quiet --depth 1 --branch "$repo_ref" \
			-- "$repo_url" "$clone_dir"
	fi
	repo_dir=$clone_dir
fi

[ -f "$repo_dir/gitconfig" ] ||
	die "No gitconfig found in $repo_dir."

mkdir -p -- "$config_dir"

if [ -e "$shared_config" ] && [ ! -L "$shared_config" ]; then
	die "Refusing to replace existing non-symlink: $shared_config"
fi

ln -sfn -- "$repo_dir/gitconfig" "$shared_config"

if [ ! -e "$local_config" ]; then
	(umask 077 && cp -- "$repo_dir/local.gitconfig.example" "$local_config")
	chmod 600 "$local_config"
	printf 'Created %s\n' "$local_config"
fi

# Ask on the terminal rather than on stdin, which holds this script when the
# installer is piped into a shell.
ask() {
	ask_reply=
	printf '%s' "$1" >/dev/tty
	IFS= read -r ask_reply </dev/tty || ask_reply=
	[ -n "$ask_reply" ] || ask_reply=$2
}

configured() {
	git config --file "$local_config" --get "$1" 2>/dev/null || true
}

# Openable, not merely present: a /dev/tty node exists in many containers where
# opening it fails, and reading it there would abort the install.
have_tty() {
	(exec 3<>/dev/tty) 2>/dev/null
}

if [ "$prompt" != never ] && { [ -z "$user_name" ] || [ -z "$user_email" ]; } &&
	have_tty; then
	printf 'Set the Git identity for this machine (Enter keeps the default).\n'

	if [ -z "$user_name" ]; then
		default_name=$(configured user.name)
		[ -n "$default_name" ] || default_name=$(git config --global --get user.name 2>/dev/null || true)
		ask "Name${default_name:+ [$default_name]}: " "$default_name"
		user_name=$ask_reply
	fi

	if [ -z "$user_email" ]; then
		default_email=$(configured user.email)
		[ -n "$default_email" ] || default_email=$(git config --global --get user.email 2>/dev/null || true)
		attempt=0
		while [ "$attempt" -lt 3 ]; do
			attempt=$((attempt + 1))
			ask "Email${default_email:+ [$default_email]}: " "$default_email"
			user_email=$ask_reply
			if [ -z "$user_email" ] || valid_email "$user_email"; then
				break
			fi
			printf 'That does not look like an email address.\n' >/dev/tty
			user_email=
		done
	fi
fi

[ -z "$user_name" ] || git config --file "$local_config" user.name "$user_name"
[ -z "$user_email" ] || git config --file "$local_config" user.email "$user_email"

if ! has_global_include; then
	git config --global --add include.path "$shared_config"
fi

printf 'Shared Git configuration enabled from %s\n' "$shared_config"

final_name=$(configured user.name)
final_email=$(configured user.email)
if [ -n "$final_name" ] && [ -n "$final_email" ]; then
	printf 'Identity: %s <%s> in %s\n' "$final_name" "$final_email" "$local_config"
else
	printf 'No identity set yet. Git will refuse to commit until you run:\n' >&2
	printf '  git config --file %s user.name "Your Name"\n' "$local_config" >&2
	printf '  git config --file %s user.email you@example.com\n' "$local_config" >&2
fi
