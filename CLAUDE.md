# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal dotfiles for macOS + Omarchy (Arch-based). Symlinks managed by `install.sh` via an explicit `LINKS` table — no GNU Stow. Repo layout mirrors `$HOME` directly: dotfiles live at repo root (`.zshrc`, `.claude/`, `.agents/`, `.config/<pkg>/`), so each `LINKS` src path reads as the `$HOME`-relative target.

Mac uses zsh as login shell (Homebrew zsh + `zsh-autosuggestions` + `zsh-syntax-highlighting`, starship prompt, no oh-my-zsh). Omarchy uses its installer-supplied bash config; this repo does **not** manage Omarchy's shell — no bash files are linked anywhere.

## Commands

- Full install / re-link: `./install.sh` (detects macOS vs Omarchy, on macOS checks the `Brewfile` via `brew bundle check` and warns if packages are missing — packages are Brewfile's job, not this script's; on Omarchy installs `PACKAGES` via `pacman` and prompts to confirm `sudo pacman -Syu` was run first). Then on macOS: `chsh` to `/opt/homebrew/bin/zsh`, apply `LINKS`, ensure `~/.zsh/private.zsh`, apply `defaults`. The top-of-script self-exec block still bootstrap-installs Homebrew bash 5.x on a fresh mac because the script itself needs Bash 4+ to parse.
- Add a new link after editing: put the new file at its `$HOME`-relative path inside the repo, add an entry to the `LINKS` array in `install.sh`, then re-run `./install.sh` (idempotent — existing links log `ok`).
- Secrets scan (pre-commit / ad hoc): `gitleaks detect` or `gitleaks protect --staged`. CI runs this on push via `.github/workflows/gitleaks.yaml`.
- Homebrew snapshot: `brew bundle dump --force --file=~/dotfiles/Brewfile` / `brew bundle install --file=~/dotfiles/Brewfile`.

No build system, no test suite. Changes ship by editing through the symlink into the repo and committing.

## Link map

The `LINKS` array in `install.sh` is the single source of truth. Each entry is `"<src-relative-to-repo>::<target-absolute>::<mode>"`. Repo root mirrors `$HOME`, so src paths look exactly like their targets with `$HOME` stripped:

- `.zshrc`, `.hushlogin` at repo root → `$HOME` — per-file links; cannot whole-dir link `$HOME`. `.zshrc` is macOS-only (`MACOS_ONLY_LINKS`). No `.zprofile` — Ghostty/Terminal open login interactive zsh shells which read `.zshrc` directly (unlike bash, which skips `.bashrc` for login shells and needs a `.bash_profile` shim).
- `.zsh/` → `$HOME/.zsh` — whole-dir symlink for zsh-side helpers (`box.zsh`, etc.). `.zshrc` sources files from here. Private/secret config goes in `~/.zsh/private.zsh` (gitignored, sourced by `.zshrc` if present, ensured-empty by `install.sh`). macOS-only.
- `.bashrc`, `.bash_profile`, `.bash/`, `.inputrc` exist in the repo but are **not in `LINKS`** — kept for rollback only (`chsh -s /opt/homebrew/bin/bash` reverts mac to bash). Omarchy uses its installer-supplied `~/.bashrc`; this repo does not touch it.
- `.claude/` → `$HOME/.claude` — **per-file + per-subdir**. `settings.json` and `statusline-command.sh` link as individual files; `agents/`, `hooks/`, `commands/` link as whole dirs. This keeps Claude Code's runtime/auth state (`projects/`, `todos/`, `statsig/`, `.credentials.json`, `settings.local.json`, etc. — gitignored) out of the repo.
- `.agents/` → `$HOME/.agents` — same pattern. `.skill-lock.json` per-file, `skills/` whole-dir. After the main loop, `install.sh` also creates a cross-package relative symlink `~/.claude/skills -> ../.agents/skills` so Claude Code discovers every installed skill without per-skill maintenance.
- `.config/{bat,ghostty,lazygit,nvim,tmux}/` → `~/.config/<pkg>` as whole-dir symlinks; `.config/starship.toml` is a per-file link.
- `.config/zed/` exists but is not in `LINKS` — edit in place / symlink manually if activating.

`.config/tmux/plugins/` and `.config/bat/themes/tokyonight.nvim` are gitignored (TPM / theme clones that land inside the whole-dir symlinks).

When `install.sh` finds a real file at a target path it backs it up to `<target>.bak.<unix_ts>` and then creates the symlink. Existing correct symlinks are left alone and logged as `ok`; existing incorrect symlinks are silently replaced (not backed up — nothing to lose).

## Install-script invariants

If you touch `install.sh`, preserve these:

- macOS vs Omarchy detection via `$OSTYPE` / `/etc/arch-release` (Omarchy ships `arch-release` since it's Arch-based).
- On **macOS** the `Brewfile` at repo root is the single source of truth for packages (formulae + casks, including `bash`, `zsh`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `ghostty`, etc.). `install.sh` runs `brew bundle check --file=$REPO/Brewfile`, warns with the `brew update && brew bundle install` command if anything's missing, and continues — it does **not** install Homebrew packages itself. To add a macOS package, edit `Brewfile` (`brew bundle dump --describe --force --file=Brewfile` to snapshot), not `install.sh`.
- On **Omarchy** there's no in-repo manifest, so `install.sh` keeps a `PACKAGES` associative array (`executable => package-name`) and `pacman -S --needed`s each entry whose key isn't already on `PATH`. `PACKAGES` keys are the executable names used for `command -v` skip-checks — key must match the binary, not the formula name (e.g. `delta` key → `git-delta` package). `PACKAGES` is only declared inside the Omarchy branch — don't reintroduce it for macOS.
- The top-of-script self-exec block bootstraps Homebrew bash 5.x on macOS (`brew install bash` then `exec /opt/homebrew/bin/bash`) so the script can use Bash 4+ syntax (associative arrays, `${var,,}`). This runs before the Brewfile check, since the check itself needs Bash 4+. Bash is **not** the login shell — it stays installed because `install.sh` itself needs it.
- After the precondition check, on macOS the script ensures `/opt/homebrew/bin/zsh` is in `/etc/shells` (sudo append if missing) and runs `chsh -s` if the user's login shell isn't already set to it. Idempotent — re-runs are no-ops. If `/opt/homebrew/bin/zsh` is missing, `chsh` is skipped with a warning (shouldn't happen post-Brewfile-check, but it's defensive).
- Never whole-dir link `$HOME/.claude` or `$HOME/.agents` — both dirs hold live runtime state. Only the individual files and stable subdirs listed in `LINKS` get symlinked.
- `REPO` is derived from `BASH_SOURCE`, so the script works from any clone location. Don't hardcode `$HOME/dotfiles`.
- `link_one` is idempotent and timestamp-backups (`.bak.<unix_ts>`) any real file it would otherwise overwrite — keep those properties.
- Bash 4+ is required (`BASH_VERSINFO` check) — macOS `/bin/bash` is 3.x, so the script runs under the Homebrew bash shebang resolver.

## Claude-config specifics (`.claude/settings.json`)

This is *this user's* Claude Code config and also ships as a stowed artifact for other machines. Preserve:

- `permissions.defaultMode: "auto"`, `skipDangerousModePermissionPrompt: true`, `alwaysThinkingEnabled: true`, `autoDreamEnabled: true` — intentional autonomous-mode defaults.
- Hooks pipeline: `uv run ~/.claude/hooks/<event>.py` for every lifecycle event. Hook scripts live in `.claude/hooks/` in this repo and link through as a whole-dir symlink. Don't remove hook entries in `settings.json` without keeping the matching script in `.claude/hooks/`.
- `statusLine.command` uses an **absolute** path `/Users/sami/.claude/statusline-command.sh`. If editing for a non-sami machine, make this `$HOME`-relative or document the rename.
- `enabledPlugins` and `extraKnownMarketplaces` (ralph, caveman) are intentional — treat as user preference, don't prune.

`statusline-command.sh` reads `$CLAUDE_CONFIG_DIR/.caveman-active`, whitelists the mode string, rejects symlinks, and caps read at 64 bytes. If extending, keep the symlink check and the `tr -cd 'a-z0-9-'` sanitization — the flag content is rendered raw to the terminal every keystroke, so unsanitized bytes become an ANSI-injection sink.

## Git / commits

`.config/git/config` (XDG path) sets `commit.gpgsign = true` with SSH signing (`id_ed25519.pub`). Commits from this repo will fail without that key present. Default branch is `main`.
