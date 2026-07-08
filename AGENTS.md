# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal dotfiles for Apple Silicon macOS, Omarchy (Arch-based), and Debian servers. Symlinks are managed by `./install.sh` plus Bash modules in `install/`; there is no GNU Stow. Repo layout mirrors `$HOME` directly: dotfiles live at repo root (`.zshrc`, `.claude/`, `.agents/`, `.config/<pkg>/`), so each link-table src path reads as the `$HOME`-relative target.

macOS and Debian use zsh as login shell with starship prompt. macOS uses Homebrew zsh/plugins under `/opt/homebrew`. Debian uses `/usr/bin/zsh` and distro zsh plugin paths when installed. Omarchy keeps its installer-supplied shell config; this repo still does **not** manage Omarchy's shell. No interactive Bash config is tracked or linked; Bash remains an installer/tooling dependency only.

## Commands

- Full install / re-link: `./install.sh`.
  - macOS: checks `Brewfile` via `brew bundle check`, warns if packages are missing, sets login shell to `/opt/homebrew/bin/zsh`, links base/AI/CLI/macOS GUI config, ensures `~/.zsh/private.zsh`, selects AeroSpace config, and applies macOS defaults.
  - Omarchy: prompts to confirm `sudo pacman -Syu` was run, installs missing packages from the Omarchy package map, and links base/AI/shared CLI config. It intentionally does not link zsh/tmux/starship shell config.
  - Debian: prompts to confirm `sudo apt-get update && sudo apt-get upgrade` was run, installs missing apt packages from the Debian package map, links base/AI/shared CLI/zsh/tmux/starship/workmux config, creates Debian `bat`/`fd` wrapper symlinks when needed, ensures `~/.zsh/private.zsh`, and sets login shell to `/usr/bin/zsh`.
- Non-interactive package-update confirmation overrides: `DOTFILES_OMARCHY_UPDATED=1 ./install.sh` or `DOTFILES_DEBIAN_UPDATED=1 ./install.sh`.
- OS override for targeted platform-path testing: `DOTFILES_OS=macos|omarchy|debian ./install.sh`. This is not a dry-run; it still performs installs/links for the selected path.
- Add a new link after editing: put the new file at its `$HOME`-relative path inside the repo, add an entry to the right link group in `install/links.sh`, then re-run `./install.sh`.
- Syntax check installer changes: `bash -n install.sh install/*.sh`.
- Syntax check zsh changes when zsh is installed: `zsh -n .zshrc .zsh/*.zsh`.
- Installer structure test: `./scripts/test-install.sh` verifies Bash syntax, zsh syntax when available, platform link composition, link-table shape, source existence, and duplicate link targets without running the real installer. It requires Bash 4+ and re-execs `/opt/homebrew/bin/bash` on macOS when available.
- Secrets scan (pre-commit / ad hoc): `gitleaks detect` or `gitleaks protect --staged`. CI runs this on push via `.github/workflows/gitleaks.yaml`.
- Homebrew snapshot: `brew bundle dump --force --file=~/dotfiles/Brewfile` / `brew bundle install --file=~/dotfiles/Brewfile`.

No build system, no formal test suite. Changes ship by editing through the symlink into the repo, running targeted syntax/behavior checks, and committing.

## Installer structure

`install.sh` is the entrypoint and keeps only the macOS Bash 4+ bootstrap, `REPO` derivation, module sourcing, OS detection, and ordered install flow. Shared/platform logic lives in:

- `install/lib.sh` — logging, Bash version check, OS detection, update-confirm prompt helper, Git hooks config, platform dispatch wrappers.
- `install/packages.sh` — package-manager helpers for pacman/apt and optional apt packages.
- `install/links.sh` — link groups, `link_one`, link application, and `~/.claude/skills -> ../.agents/skills` cross-link.
- `install/shell.sh` — login-shell setup and `~/.zsh/private.zsh` creation.
- `install/tmux.sh` — tmux-sessionizer install.
- `install/macos.sh` — Brewfile check, macOS link composition, zsh setup, AeroSpace config selection, macOS defaults.
- `install/omarchy.sh` — Omarchy package map and link composition; no shell management.
- `install/debian.sh` — Debian apt package map, link composition, zsh setup, and `bat`/`fd` wrapper symlinks.

If you add a platform, add a new `install/<platform>.sh` exposing `<platform>_preconditions`, `<platform>_install_packages`, `<platform>_add_links`, `<platform>_setup_shell`, and `<platform>_post_install`, then update `detect_os`/module sourcing.

## Link map

Link groups in `install/links.sh` are the source of truth. Each entry is `"<src-relative-to-repo>::<target-absolute>::<mode>"`. Repo root mirrors `$HOME`, so src paths look exactly like their targets with `$HOME` stripped.

- `LINKS_BASE`: `.hushlogin`, `.config/git/config`.
- `LINKS_AI`: stable `.claude/` files/subdirs and `.agents/` files/subdirs. Never whole-dir link `$HOME/.claude` or `$HOME/.agents`; both hold live runtime/auth state.
- `LINKS_SHARED_CLI`: cross-platform CLI app configs such as bat, lazygit, mise, nvim, and workmux.
- `LINKS_ZSH`: `.zshrc`, `.zsh/`, tmux, tmux-sessionizer, and starship. Used by macOS and Debian, not Omarchy.
- `LINKS_MAC_GUI`: AeroSpace, borders, Ghostty.
- `LINKS_MAC_EXTRA`: Homebrew config.

Profile composition:

- macOS: `BASE + AI + SHARED_CLI + ZSH + MAC_GUI + MAC_EXTRA`.
- Omarchy: `BASE + AI + SHARED_CLI` only; Omarchy shell stays managed by Omarchy.
- Debian: `BASE + AI + SHARED_CLI + ZSH`; Debian keeps workmux via `LINKS_SHARED_CLI`.

`.config/aerospace/` is whole-dir linked on macOS, but its active config `aerospace.toml` is a per-machine relative symlink (`-> work.toml` | `-> personal.toml`, or any other `*.toml` in the dir) created interactively by `install/macos.sh`. It's gitignored — the machine's work/personal choice isn't committed.

`.config/zed/` exists but is not linked — edit in place / symlink manually if activating.

`.config/tmux/plugins/`, `.config/bat/themes/tokyonight.nvim`, and `.config/aerospace/aerospace.toml` are gitignored (TPM / theme clones and the per-machine aerospace selection that land inside whole-dir symlinks).

`link_one` must stay idempotent and timestamp-backup (`.bak.<unix_ts>`) any real file it would otherwise overwrite. Existing correct symlinks are left alone and logged `ok`; existing incorrect symlinks are replaced.

## Zsh structure

`.zshrc` is a small shared entrypoint:

- returns immediately for non-interactive shells
- sources `.zsh/common.zsh`
- sources `.zsh/macos.zsh` on Darwin
- sources `.zsh/linux.zsh` on Linux
- sources `~/.zsh/private.zsh` last when present

`.zsh/common.zsh` holds portable shell behavior: editor env, history, XDG paths, PATH construction (including Apple Silicon Homebrew shellenv on macOS), completions, keybinds, guarded eza/bat/zoxide/fzf/mise/starship setup, common aliases, and `box.zsh` sourcing.

`.zsh/macos.zsh` holds macOS clipboard aliases, `brew`/`flushdns`, and Homebrew zsh plugin paths.

`.zsh/linux.zsh` holds Linux zsh plugin paths. Debian links zsh config and starship config; starship initialization remains guarded by `command -v starship`. Debian installs `git-delta`, `zoxide`, and `starship` as optional APT packages when available so missing optional packages do not block the base server setup.

`.zsh/box.zsh` must stay portable: use `scutil` only when present and fall back to `hostname -s`/`hostname`.

Private/secret zsh config goes in `~/.zsh/private.zsh` (gitignored, sourced by `.zshrc` if present, ensured-empty by installer on macOS and Debian).

No interactive Bash config is tracked or linked. Bash files in this repo are installer/tooling scripts only; do not add `.bashrc`, `.bash_profile`, `.bash/`, or `.inputrc` back unless intentionally reintroducing Bash as a managed user shell.

## Install-script invariants

If you touch installer code, preserve these:

- macOS detection via `$OSTYPE`; Omarchy detection via `/etc/arch-release`; Debian detection via `/etc/os-release` `ID=debian` or Debian-like `ID_LIKE`.
- Apple Silicon macOS only is supported; `/opt/homebrew` paths are intentional.
- On macOS, `Brewfile` remains the single source of truth for packages. `install.sh` checks it and warns, but does not install Brewfile packages itself. To add a macOS package, edit `Brewfile`.
- On Omarchy, package maps are `executable => package-name` and installed through `pacman -S --needed --noconfirm` after the update confirmation.
- On Debian, package maps are mostly `executable => package-name` and installed through `apt-get install -y`; handle Debian command-name mismatches (`batcat`/`fdfind`) in `install/debian.sh` wrappers.
- The top-of-script self-exec block bootstraps Homebrew bash 5.x on macOS (`brew install bash` then `exec /opt/homebrew/bin/bash`) before modules are sourced. Bash is not the login shell; it stays installed because the installer needs Bash 4+.
- `REPO` is derived from `BASH_SOURCE`, so the script works from any clone location. Do not hardcode `$HOME/dotfiles`.
- Configure committed Git hooks with `git -C "$REPO" config core.hooksPath .githooks`.
- `tmux-sessionizer` install must avoid fixed `/tmp` paths; use a fresh temp dir.
- Interactive prompts must be TTY-safe and have env overrides for non-interactive runs.
- Bash 4+ is required.

## Claude-config specifics (`.claude/settings.json`)

This is this user's Claude Code config and also ships as a linked artifact for other machines. Preserve:

- `permissions.defaultMode: "bypassPermissions"`, `skipDangerousModePermissionPrompt: true`, `alwaysThinkingEnabled: true`, `autoDreamEnabled: true` — intentional autonomous-mode defaults.
- Hooks pipeline: only `PreToolUse` runs a custom script (`uv run ~/.claude/hooks/pre_tool_use.py`) — it blocks `rm -rf` variants and reads/writes to `.env*` / `*.tfvars` / `*.auto.tfvars` (exit code 2). Other lifecycle events may invoke Superset notify/workmux commands. Hook scripts live in `.claude/hooks/` and link through as a whole-dir symlink. If adding a new Python hook, drop the file in `.claude/hooks/` and wire it in `settings.json`; if removing, prune both sides.
- `statusLine.command` uses `bash -c 'exec "$HOME/.claude/statusline-command.sh"'` so the shared settings file works on macOS and Debian home paths without sourcing login-shell startup files on every statusline render. Preserve `$HOME` resolution if editing it.
- `statusline-command.sh` reads Claude's statusline JSON from stdin with `jq`, then prints branch, model, effort, and context-window usage with ANSI colors. If extending it, keep missing-field handling tolerant so older/newer Claude statusline payloads do not break the prompt.

## Git / commits

`.config/git/config` (XDG path) sets `commit.gpgsign = true` with SSH signing (`id_ed25519.pub`). Commits from this repo will fail without that key present. Default branch is `main`.
