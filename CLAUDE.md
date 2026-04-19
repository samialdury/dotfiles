# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal dotfiles for macOS + Arch Linux. Symlinks managed by `install.sh` via an explicit `LINKS` table — no GNU Stow. Each top-level directory still mirrors the target install tree purely as an organising convention.

## Commands

- Full install / re-link: `./install.sh` (detects macOS vs Arch, installs packages, applies the `LINKS` table, applies macOS `defaults`). Prompts to confirm `brew update` / `sudo pacman -Syu` was run first; reject with anything other than `y`/`yes` and it exits.
- Add a new link after editing: put the new file under the right package dir, add an entry to the `LINKS` array in `install.sh`, then re-run `./install.sh` (idempotent — existing links log `ok`).
- Secrets scan (pre-commit / ad hoc): `gitleaks detect` or `gitleaks protect --staged`. CI runs this on push via `.github/workflows/gitleaks.yaml`.
- Homebrew snapshot: `brew bundle dump --force --file=~/dotfiles/Brewfile` / `brew bundle install --file=~/dotfiles/Brewfile`.

No build system, no test suite. Changes ship by editing through the symlink into the repo and committing.

## Link map

The `LINKS` array in `install.sh` is the single source of truth. Each entry is `"<src-relative-to-repo>::<target-absolute>::<mode>"`. Repo layout mirrors targets so entries read naturally:

- `home/` → `$HOME` directly (`.bashrc`, `.bash_profile`, `.gitconfig`, `.hushlogin`) — per-file links; cannot whole-dir link `$HOME`.
- `claude/.claude/` → `$HOME/.claude` — **per-file + per-subdir**. `settings.json` and `statusline-command.sh` link as individual files; `agents/`, `hooks/`, `commands/` link as whole dirs. This keeps Claude Code's runtime/auth state (`projects/`, `todos/`, `statsig/`, `.credentials.json`, `settings.local.json`, etc. — gitignored) out of the repo.
- `agents/.agents/` → `$HOME/.agents` — same pattern. `.skill-lock.json` per-file, `skills/` whole-dir. After the main loop, `install.sh` also creates a cross-package relative symlink `~/.claude/skills -> ../.agents/skills` so Claude Code discovers every installed skill without per-skill maintenance.
- `fish/.config/fish/` → `~/.config/fish` — **whole-dir symlink**. Shell-local state (`conf.d/`, `completions/`, `fish_variables`, `private.fish`, history) materializes inside the symlinked dir, so `.gitignore` uses a whitelist pattern (`fish/.config/fish/*` ignored, `!config.fish` + `!functions/**` tracked).
- `bat`, `ghostty`, `lazygit`, `nvim`, `starship`, `tmux` → `~/.config/<pkg>` as whole-dir symlinks.
- `zed`, `hammerspoon` exist in the repo but are not in `LINKS` — edit in place / symlink manually if activating.

`tmux/.config/tmux/plugins/` and `bat/.config/bat/themes/tokyonight.nvim` are gitignored (TPM / theme clones that land inside the whole-dir symlinks).

When `install.sh` finds a real file at a target path it backs it up to `<target>.bak.<unix_ts>` and then creates the symlink. Existing correct symlinks are left alone and logged as `ok`; existing incorrect symlinks are silently replaced (not backed up — nothing to lose).

## Install-script invariants

If you touch `install.sh`, preserve these:

- macOS vs Arch detection via `$OSTYPE` / `/etc/arch-release`. Any new package goes in the `PACKAGES` associative array (`executable => package-name`); macOS-only ones in `MACOS_ONLY_PACKAGES`.
- `PACKAGES` keys are the executable names used for `command -v` skip-checks — key must match the binary, not the brew/pacman formula name (e.g. `delta` key → `git-delta` package).
- Never whole-dir link `$HOME/.claude` or `$HOME/.agents` — both dirs hold live runtime state. Only the individual files and stable subdirs listed in `LINKS` get symlinked.
- `REPO` is derived from `BASH_SOURCE`, so the script works from any clone location. Don't hardcode `$HOME/dotfiles`.
- `link_one` is idempotent and timestamp-backups (`.bak.<unix_ts>`) any real file it would otherwise overwrite — keep those properties.
- Bash 4+ is required (`BASH_VERSINFO` check) — macOS `/bin/bash` is 3.x, so the script runs under the Homebrew bash shebang resolver.

## Claude-config specifics (`claude/.claude/settings.json`)

This is *this user's* Claude Code config and also ships as a stowed artifact for other machines. Preserve:

- `permissions.defaultMode: "auto"`, `skipDangerousModePermissionPrompt: true`, `alwaysThinkingEnabled: true`, `autoDreamEnabled: true` — intentional autonomous-mode defaults.
- Hooks pipeline: `uv run ~/.claude/hooks/<event>.py` for every lifecycle event. Hook scripts live in `claude/.claude/hooks/` in this repo and link through as a whole-dir symlink. Don't remove hook entries in `settings.json` without keeping the matching script in `claude/.claude/hooks/`.
- `statusLine.command` uses an **absolute** path `/Users/sami/.claude/statusline-command.sh`. If editing for a non-sami machine, make this `$HOME`-relative or document the rename.
- `enabledPlugins` and `extraKnownMarketplaces` (ralph, caveman) are intentional — treat as user preference, don't prune.

`statusline-command.sh` reads `$CLAUDE_CONFIG_DIR/.caveman-active`, whitelists the mode string, rejects symlinks, and caps read at 64 bytes. If extending, keep the symlink check and the `tr -cd 'a-z0-9-'` sanitization — the flag content is rendered raw to the terminal every keystroke, so unsanitized bytes become an ANSI-injection sink.

## Git / commits

`home/.gitconfig` sets `commit.gpgsign = true` with SSH signing (`id_ed25519.pub`). Commits from this repo will fail without that key present. Default branch is `main`.
