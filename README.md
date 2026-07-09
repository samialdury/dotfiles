# dotfiles

Personal dotfiles for Apple Silicon macOS, Omarchy, and Debian servers.

The repository mirrors `$HOME`: tracked paths such as `.zshrc`, `.claude/`, `.agents/`, and `.config/<tool>/` are linked into place by `./install.sh`. There is no GNU Stow layer.

## What this repo manages

- **macOS:** zsh login shell, Homebrew package manifest, GUI/CLI app config, Claude config, AeroSpace config selection, and macOS defaults.
- **Debian:** zsh login shell, shared CLI config, tmux/starship/workmux config, Claude config, and Debian command wrapper symlinks.
- **Omarchy:** shared CLI, AI, Git, nvim, workmux, and package setup. Omarchy's shell stays managed by Omarchy.

## Quick start

```sh
git clone git@github.com:samialdury/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

For a fresh machine, start with the full bootstrap guide:

- [Installation guide](docs/INSTALLATION.md)

## Documentation

- [Installation](docs/INSTALLATION.md) — SSH key setup, macOS bootstrap, Omarchy setup, Debian setup, and secrets restore checklist.
- [Maintenance](docs/MAINTENANCE.md) — adding links, Homebrew snapshots, verification commands, hooks, CI, and shell-config rules.
- [Troubleshooting](docs/TROUBLESHOOTING.md) — GitHub SSH, commit signing, and common install issues.
- [Hyprland notes](docs/HYPRLAND.md) — personal Hyprland input/touchpad snippet kept out of the top-level README.
- [Remote workstation](docs/REMOTE_WORKSTATION.md) — Wake-on-LAN, Tailscale, mosh, and tmux workflow for the home box.

## Verification

Run the verification harness manually when you want a quick check:

```sh
./scripts/test-install.sh
```

The committed pre-commit hook runs the same harness and blocks the commit if verification fails.

Secrets scan:

```sh
gitleaks git --pre-commit --staged --redact --verbose
gitleaks git --redact --verbose
```

The committed pre-commit hook runs the staged Gitleaks scan before the verification harness.

CI runs the structure/syntax checks through `.github/workflows/verify.yaml`, workflow linting through `.github/workflows/actionlint.yaml`, and secret scanning through `.github/workflows/gitleaks.yaml`.

## Repository map

- `install.sh` — installer entrypoint and platform dispatch.
- `install/` — Bash modules for package setup, link composition, shell setup, tmux-sessionizer, and platform-specific behavior.
- `scripts/test-install.sh` — safe structure harness; it does not run the real installer.
- `.zshrc`, `.zsh/` — zsh entrypoint and shared/macOS/Linux shell config.
- `.claude/`, `.agents/` — Claude Code config, hooks, commands, agents, and shared skills.
- `.config/` — app configs linked by platform-specific profiles.
- `.githooks/` — committed Git hooks; `./install.sh` sets `core.hooksPath` to this directory.

## License

[MIT](LICENSE)
