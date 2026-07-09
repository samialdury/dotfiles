# Maintenance

This page is for routine upkeep: package snapshots, link-table changes, hooks, verification, and shell-config rules.

## Add a managed link

`install/links.sh` is the source of truth. Each entry has this shape:

```text
<src-relative-to-repo>::<target-absolute>::<mode>
```

Example:

```bash
".config/example::$HOME/.config/example::dir"
```

Rules:

- source paths are relative to the repo root
- source paths mirror `$HOME` paths where possible
- mode is `file` or `dir`
- targets must be unique
- sources must exist
- never whole-dir link `$HOME/.claude` or `$HOME/.agents`

After editing link tables:

```sh
./scripts/test-install.sh
./install.sh
```

## Homebrew snapshot

The Brewfile is the macOS package source of truth.

```sh
brew bundle dump --describe --force --file=~/dotfiles/Brewfile
brew bundle install --file=~/dotfiles/Brewfile
brew bundle check --file=~/dotfiles/Brewfile
brew bundle list --file=~/dotfiles/Brewfile
brew bundle cleanup --file=~/dotfiles/Brewfile
brew bundle cleanup --file=~/dotfiles/Brewfile --force
```

`./install.sh` checks the Brewfile on macOS and warns when packages are missing. It does not install Brewfile packages itself, except for the early Homebrew Bash bootstrap needed to parse the installer.

## Verification commands

Safe structure harness:

```sh
./scripts/test-install.sh
```

Syntax checks:

```sh
bash -n install.sh install/*.sh .githooks/pre-commit scripts/test-install.sh .claude/statusline-command.sh
zsh -n .zshrc .zsh/*.zsh
```

Secrets checks:

```sh
gitleaks detect
gitleaks protect --staged
```

## CI

GitHub Actions workflows:

- `.github/workflows/verify.yaml` — ShellCheck, installer structure harness, and Bash syntax checks.
- `.github/workflows/gitleaks.yaml` — secret scanning with full git history.

## Git hooks

Committed hooks live in `.githooks/`. The installer runs:

```sh
git -C "$REPO" config core.hooksPath .githooks
```

The current pre-commit hook formats staged `.claude/settings.json` with `jq -S` when that file is staged and the working copy has no unstaged edits to the same file.

## Shell config policy

Repo-managed interactive shell config is zsh:

- `.zshrc`
- `.zsh/common.zsh`
- `.zsh/macos.zsh`
- `.zsh/linux.zsh`
- `.zsh/box.zsh`

Installer and hook scripts are Bash:

- `install.sh`
- `install/*.sh`
- `.githooks/pre-commit`
- `scripts/test-install.sh`
