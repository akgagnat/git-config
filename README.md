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

1. Symlinks the tracked config to `~/.config/git-config/shared.gitconfig`.
2. Adds that stable path as a global Git include without replacing existing
   global configuration.
3. Creates `~/.config/git-config/local.gitconfig` from
   [`local.gitconfig.example`](local.gitconfig.example), with owner-only
   permissions, if it does not already exist.

Set your name and email in the local file. Its values override the shared
configuration and are not tracked by this repository.

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
conflict markers, and supplies compact status/log aliases. It intentionally
does not set an editor, credential helper, signing key, or identity because
those are machine- or person-specific.
