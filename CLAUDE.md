# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal dotfiles for macOS + Arch Linux. Managed via GNU Stow — each top-level directory is a Stow package that mirrors the target install tree.

## Commands

- Full install / re-stow: `./install.sh` (detects macOS vs Arch, installs packages, stows dirs, applies macOS `defaults`). Prompts to confirm `brew update` / `sudo pacman -Syu` was run first; reject with anything other than `y`/`yes` and it exits.
- Stow a single package after editing: `stow <pkg>` from repo root (e.g. `stow fish`). Unstow with `stow -D <pkg>`.
- Secrets scan (pre-commit / ad hoc): `gitleaks detect` or `gitleaks protect --staged`. CI runs this on push via `.github/workflows/gitleaks.yaml`.
- Homebrew snapshot: `brew bundle dump --force --file=~/dotfiles/Brewfile` / `brew bundle install --file=~/dotfiles/Brewfile`.

No build system, no test suite. Changes ship by re-stowing or editing the symlinked target file directly.

## Stow layout

Each top-level dir is a Stow package; contents mirror where they land. Target map lives in `install.sh` (`STOW_TARGETS`):

- `home/` → `$HOME` directly (`.bashrc`, `.bash_profile`, `.gitconfig`, `.hushlogin`)
- `claude/.claude/` → `$HOME/.claude` — **folded, not whole-dir symlinked**. Runtime/auth state (`projects/`, `todos/`, `statsig/`, `.credentials.json`, `settings.local.json`) stays out of the repo (see `.gitignore`). `install.sh` explicitly `mkdir -p ~/.claude` and backs up `settings.json` to `.bak` before stowing so Stow folds individual files rather than linking the whole dir.
- `agents/.agents/` → `$HOME/.agents` — **folded, not whole-dir symlinked**, same reasoning as `~/.claude`. Holds installed agent skills (`skills/`) and the `.skill-lock.json` version pin. `install.sh` does `mkdir -p ~/.agents` and backs up `.skill-lock.json` to `.bak` before stowing so skill-tooling runtime writes stay out of the repo. After stow, `install.sh` creates a single whole-dir symlink `~/.claude/skills -> ../.agents/skills` so Claude Code discovers every installed skill without per-skill links.
- `fish/.config/fish/` → `~/.config/fish` — `conf.d/`, `completions/`, `fish_variables`, and `private.fish` are gitignored (host/shell-local state).
- `bat`, `ghostty`, `lazygit`, `nvim`, `starship`, `tmux` → `~/.config/<pkg>`.
- `zed`, `hammerspoon` exist but are not in the `STOW_DIRS` loop — edit in place / symlink manually if activating.

`tmux/.config/tmux/plugins/` and `bat/.config/bat/themes/tokyonight.nvim` are gitignored (TPM / theme clones).

When editing a stowed file you're writing through the symlink into the repo — commit from the repo. When adding a *new* config file, place it inside the package dir, then re-run `stow <pkg>` so the symlink appears in the target.

## Install-script invariants

If you touch `install.sh`, preserve these:

- macOS vs Arch detection via `$OSTYPE` / `/etc/arch-release`. Any new package goes in the `PACKAGES` associative array (`executable => package-name`); macOS-only ones in `MACOS_ONLY_PACKAGES`.
- `PACKAGES` keys are the executable names used for `command -v` skip-checks — key must match the binary, not the brew/pacman formula name (e.g. `delta` key → `git-delta` package).
- The `claude` stow step must never move the whole `~/.claude` dir (live auth state). Only `settings.json` is backed up.
- The `agents` stow step must never move the whole `~/.agents` dir either — only `.skill-lock.json` is backed up. Fold mode is required so future skill-tooling runtime writes don't land in the repo.
- Bash 4+ is required (`BASH_VERSINFO` check) — macOS `/bin/bash` is 3.x, so the script runs under the Homebrew bash shebang resolver.

## Claude-config specifics (`claude/.claude/settings.json`)

This is *this user's* Claude Code config and also ships as a stowed artifact for other machines. Preserve:

- `permissions.defaultMode: "auto"`, `skipDangerousModePermissionPrompt: true`, `alwaysThinkingEnabled: true`, `autoDreamEnabled: true` — intentional autonomous-mode defaults.
- Hooks pipeline: `uv run ~/.claude/hooks/<event>.py` for every lifecycle event. The `hooks/` dir is `.gitkeep`-only in this repo — hook scripts live elsewhere / are user-local. Don't remove hook entries without the user's scripts to replace them.
- `statusLine.command` uses an **absolute** path `/Users/sami/.claude/statusline-command.sh`. If editing for a non-sami machine, make this `$HOME`-relative or document the rename.
- `enabledPlugins` and `extraKnownMarketplaces` (ralph, caveman) are intentional — treat as user preference, don't prune.

`statusline-command.sh` reads `$CLAUDE_CONFIG_DIR/.caveman-active`, whitelists the mode string, rejects symlinks, and caps read at 64 bytes. If extending, keep the symlink check and the `tr -cd 'a-z0-9-'` sanitization — the flag content is rendered raw to the terminal every keystroke, so unsanitized bytes become an ANSI-injection sink.

## Git / commits

`home/.gitconfig` sets `commit.gpgsign = true` with SSH signing (`id_ed25519.pub`). Commits from this repo will fail without that key present. Default branch is `main`.
