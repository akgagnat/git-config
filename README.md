# Git configuration

Portable, non-secret Git preferences for setting up a new machine. The tracked
[`gitconfig`](gitconfig) contains shared behavior and aliases only. Identity,
signing preferences, credentials, and private keys stay outside this repository.

## Install

On a new machine, with nothing checked out yet:

```sh
curl -fsSL https://raw.githubusercontent.com/akgagnat/git-config/main/install.sh | sh
```

The installer asks for the name and email to use for commits on this machine.
It reads the answers from the terminal, not from standard input, so prompting
works even when the script itself arrives on the pipe.

Or, from a checkout:

```sh
./install.sh
```

The installer:

1. Clones this repository to `${XDG_DATA_HOME:-~/.local/share}/git-config` when
   run outside a checkout, and fast-forwards that clone on later runs. Run from
   a checkout, it uses that checkout instead and clones nothing.
2. Symlinks the tracked config to `<config dir>/shared.gitconfig`, where
   `<config dir>` is `${XDG_CONFIG_HOME:-~/.config}/git-config`.
3. Adds that stable path as a global Git include without replacing existing
   global configuration.
4. Creates `<config dir>/local.gitconfig` from
   [`local.gitconfig.example`](local.gitconfig.example), with owner-only
   permissions, if it does not already exist, and writes the identity into it.

The shared config includes `local.gitconfig` by relative path, so it resolves
next to the symlink and follows `XDG_CONFIG_HOME` automatically. Local values
override the shared configuration and are not tracked by this repository.

Rerunning the installer is safe: the include is added once, and an existing
`local.gitconfig` is updated in place rather than replaced.

### Options

```
--name NAME      Use NAME as user.name instead of asking.
--email EMAIL    Use EMAIL as user.email instead of asking.
--no-prompt      Never ask; keep whatever identity is already configured.
--ref REF        Branch or tag to clone when bootstrapping (default: main).
--uninstall      Remove the global include and the shared symlink.
```

`GIT_CONFIG_NAME`, `GIT_CONFIG_EMAIL`, `GIT_CONFIG_REPO_URL`,
`GIT_CONFIG_REPO_REF`, and `GIT_CONFIG_CLONE_DIR` set the same values from the
environment. Pass options through the pipe after `-s --`:

```sh
curl -fsSL https://raw.githubusercontent.com/akgagnat/git-config/main/install.sh |
	sh -s -- --name 'Your Name' --email you@example.com
```

Without a terminal and without those values — in CI, say — the installer skips
the prompt, finishes the rest of the setup, and prints the commands to set the
identity later. Because the shared config sets `user.useConfigOnly`, Git
refuses to commit until an identity exists, rather than guessing one from your
hostname and login name.

To remove the global include and the symlink, keeping your local identity file
and the clone:

```sh
./install.sh --uninstall
```

### Piping to a shell

`curl … | sh` runs whatever the server returns. That is worth doing only for a
repository you control and over HTTPS, as above. To read the script first:

```sh
curl -fsSL https://raw.githubusercontent.com/akgagnat/git-config/main/install.sh -o install.sh
less install.sh
sh install.sh
```

The raw URL serves the public repository without authentication. If the
repository is made private, the URL stops working for `curl`; clone it over SSH
and run `./install.sh` from the checkout instead.

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
