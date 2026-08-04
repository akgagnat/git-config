# Git configuration

Portable, non-secret Git preferences for setting up a new machine. The tracked
[`gitconfig`](gitconfig) contains shared behavior and aliases only. Identity,
signing preferences, credentials, and private keys stay outside this repository.

## Install

Clone this repository, then run:

```bash
./install.sh
```

The installer:

1. Symlinks the tracked config to `<config dir>/shared.gitconfig`, where
   `<config dir>` is `${XDG_CONFIG_HOME:-~/.config}/git-config`.
2. Adds that stable path as a global Git include without replacing existing
   global configuration.
3. Creates `<config dir>/local.gitconfig` from
   [`local.gitconfig.example`](local.gitconfig.example), with owner-only
   permissions, if it does not already exist.

The shared config includes `local.gitconfig` by relative path, so it resolves
next to the symlink and follows `XDG_CONFIG_HOME` automatically.

Set your name and email in the local file; they are commented out by default.
Because the shared config sets `user.useConfigOnly`, Git refuses to commit
until you do, rather than guessing an identity from your hostname and login
name. Local values override the shared configuration and are not tracked by
this repository.

To remove the global include and the symlink, keeping your local identity
file:

```bash
./install.sh --uninstall
```

## Sensitive values

Do not put personal access tokens, passwords, private SSH keys, GPG private
keys, or credential-helper secrets in this repository or in `gitconfig`.

- Authenticate GitHub CLI separately with `gh auth login`.
- Store SSH keys under `~/.ssh/` with restrictive permissions.
- Import GPG private keys into your local keyring; only an optional public key
  fingerprint belongs in `local.gitconfig`.

Review active configuration and its sources with:

```bash
git config --show-origin --list
```

## Shared behavior

The shared configuration uses `main` for new repositories, prunes deleted
remote branches, requires fast-forward pulls, enables rerere, uses `zdiff3`
conflict markers, and supplies compact status/log aliases. It also sorts
branches by recency and tags by version, enables rebase `autoSquash` and
`updateRefs` for stacked branches, pushes tags alongside commits, and turns on
`fsckObjects` for fetch, receive, and transfer so malformed or malicious
objects are rejected. `git log` uses a colored format with abbreviated commit
hash, decorations, subject, relative time, and author.

It intentionally does not set an editor, credential helper, signing key, or
identity because those are machine- or person-specific.

## License

[MIT](LICENSE)
