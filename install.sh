#!/usr/bin/env bash

# Re-exec under Homebrew bash 5.x if env bash resolved to macOS system bash 3.2.
# Needed before any Bash 4+ syntax (associative arrays, ${var,,}) is parsed.
# On fresh machines brew bash may not exist yet — bootstrap-install it first
# so the rest of the script (Bash 4+ only) can run. The Brewfile precondition
# check below then enforces that the rest of the formulae/casks are installed.
if ((BASH_VERSINFO[0] < 4)); then
  if [ -x /opt/homebrew/bin/bash ]; then
    exec /opt/homebrew/bin/bash "$0" "$@"
  elif command -v brew >/dev/null 2>&1; then
    echo "[setup][info] Bootstrapping Homebrew bash 5.x (script needs Bash 4+)..."
    brew install bash
    exec /opt/homebrew/bin/bash "$0" "$@"
  fi
fi

set -euo pipefail

# -----------------------------
# Logging
# -----------------------------
RESET='\033[0m'
BLUE='\033[34m'
YELLOW='\033[33m'
RED='\033[31m'
GREEN='\033[32m'

log_info() { printf "%b[setup][info]%b %s\n" "$BLUE" "$RESET" "$*"; }
log_warn() { printf "%b[setup][warn]%b %s\n" "$YELLOW" "$RESET" "$*"; }
log_error() { printf "%b[setup][error]%b %s\n" "$RED" "$RESET" "$*"; }
log_success() { printf "%b[setup][success]%b %s\n" "$GREEN" "$RESET" "$*"; }

# -----------------------------
# Bash version check
# -----------------------------
if ((BASH_VERSINFO[0] < 4)); then
  log_error "This script requires bash 4+. Install a newer bash and re-run."
  exit 1
fi

# -----------------------------
# Detect OS
# -----------------------------
if [[ "${OSTYPE:-}" == darwin* ]]; then
  OS_TYPE="macos"
elif [[ -f /etc/arch-release ]]; then
  OS_TYPE="omarchy"
else
  log_error "Unsupported OS. This script only supports macOS and Omarchy."
  exit 1
fi

log_info "Detected OS: $OS_TYPE"

# Repo root — referenced early (Brewfile precondition) and later (symlinks).
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -----------------------------
# Check package manager
# -----------------------------
case "$OS_TYPE" in
macos)
  if ! command -v brew >/dev/null 2>&1; then
    log_error "Homebrew not found. Install it from https://brew.sh"
    exit 1
  fi
  ;;
omarchy)
  if ! command -v pacman >/dev/null 2>&1; then
    log_error "pacman not found. This does not look like a real Omarchy system."
    exit 1
  fi
  ;;
esac

# -----------------------------
# Package preconditions
#
# macOS: the Brewfile is the single source of truth for installed packages
# (formulae + casks). This script only does the things Homebrew can't:
# symlinks, chsh, macOS defaults, tmux-sessionizer. Warn if Brewfile hasn't
# been applied yet so the user can install missing packages separately.
#
# Omarchy: no equivalent manifest in-repo, so install required pacman packages
# directly below and confirm `pacman -Syu` was run first.
# -----------------------------
if [[ "$OS_TYPE" == "macos" ]]; then
  BREWFILE="$REPO/Brewfile"
  if [ ! -f "$BREWFILE" ]; then
    log_error "Brewfile missing at $BREWFILE"
    exit 1
  fi
  log_info "Checking Brewfile state: $BREWFILE"
  if ! brew bundle check --file="$BREWFILE" >/dev/null 2>&1; then
    log_warn "Brewfile not fully installed. Continuing anyway."
    log_warn "To install missing packages, run:"
    log_warn "  brew update && brew bundle install --file=$BREWFILE"
  else
    log_success "Brewfile satisfied."
  fi
else
  UPDATE_CMD="sudo pacman -Syu"
  log_warn "Before running this script, you *must* fully update your Omarchy system:"
  log_warn "  $UPDATE_CMD"
  printf "%b[setup]%b Have you run '%s'? (y/yes to continue): " "$BLUE" "$RESET" "$UPDATE_CMD"
  read -r CONFIRM

  case "${CONFIRM,,}" in
  y | yes)
    log_info "Continuing..."
    ;;
  *)
    log_error "You must run '$UPDATE_CMD' before using this script. Exiting."
    exit 1
    ;;
  esac
fi

# -----------------------------
# Omarchy packages (pacman). Format: executable => package name.
# Key must match the binary name used by `command -v`, not the formula name
# (e.g. `delta` key → `git-delta` package).
# -----------------------------
if [[ "$OS_TYPE" == "omarchy" ]]; then
  declare -A PACKAGES=(
    ["bat"]="bat"
    ["delta"]="git-delta"
    ["lazygit"]="lazygit"
    ["nvim"]="neovim"
    ["starship"]="starship"
    ["tmux"]="tmux"
    ["rg"]="ripgrep"
    ["fd"]="fd"
    ["fzf"]="fzf"
    ["just"]="just"
  )

  for cmd in "${!PACKAGES[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      log_info "Installing package: ${PACKAGES[$cmd]}"
      sudo pacman -S --needed --noconfirm "${PACKAGES[$cmd]}"
      log_success "Finished installing: ${PACKAGES[$cmd]}"
    else
      log_info "$cmd already installed, skipping..."
    fi
  done
fi

# -----------------------------
# Install tmux-sessionizer (both OSes; not packaged in Brewfile/pacman)
# -----------------------------
TS_BIN="$HOME/.local/scripts/tmux-sessionizer"

if ! command -v tmux-sessionizer >/dev/null 2>&1 && [ ! -x "$TS_BIN" ]; then
  log_info "Installing tmux-sessionizer..."
  git clone https://github.com/ThePrimeagen/tmux-sessionizer.git /tmp/tmux-sessionizer

  mkdir -p "$HOME/.local/scripts"
  mv /tmp/tmux-sessionizer/tmux-sessionizer "$TS_BIN"
  chmod +x "$TS_BIN"
  rm -rf /tmp/tmux-sessionizer

  log_success "tmux-sessionizer installed."
  log_warn "Make sure \$HOME/.local/scripts is in your PATH."
else
  log_info "tmux-sessionizer already installed, skipping..."
fi

log_success "Install step finished."

# -----------------------------
# Set zsh as default login shell (macOS only)
# -----------------------------
if [[ "$OS_TYPE" == "macos" ]]; then
  TARGET_SHELL="/opt/homebrew/bin/zsh"
  if [ ! -x "$TARGET_SHELL" ]; then
    log_warn "Skipping chsh — $TARGET_SHELL not present."
  else
    if ! grep -qx "$TARGET_SHELL" /etc/shells; then
      log_warn "Adding $TARGET_SHELL to /etc/shells (requires sudo)..."
      echo "$TARGET_SHELL" | sudo tee -a /etc/shells >/dev/null
    fi
    if [[ "${SHELL:-}" != "$TARGET_SHELL" ]]; then
      log_warn "Changing login shell to $TARGET_SHELL (will prompt for password)..."
      chsh -s "$TARGET_SHELL"
      log_success "Default shell set to $TARGET_SHELL. Open a new terminal for it to take effect."
    else
      log_info "Default shell already $TARGET_SHELL, skipping chsh..."
    fi
  fi
fi

# -----------------------------
# Link dotfiles into target locations
# -----------------------------

# Format per entry: "<src-relative-to-repo>::<target-absolute>::<mode>"
# Mode is informational only right now (file vs dir); link_one treats both the same.
declare -a LINKS=(
  # Flat $HOME files
  ".hushlogin::$HOME/.hushlogin::file"

  # ~/.config/<pkg> whole-dir links
  ".config/bat::$HOME/.config/bat::dir"
  ".config/git/config::$HOME/.config/git/config::file"
  ".config/lazygit::$HOME/.config/lazygit::dir"
  ".config/mise/config.toml::$HOME/.config/mise/config.toml::file"
  ".config/nvim::$HOME/.config/nvim::dir"
  ".config/workmux::$HOME/.config/workmux::dir"

  # ~/.claude — per-file + per-subdir so runtime state stays out of repo
  ".claude/settings.json::$HOME/.claude/settings.json::file"
  ".claude/statusline-command.sh::$HOME/.claude/statusline-command.sh::file"
  ".claude/agents::$HOME/.claude/agents::dir"
  ".claude/hooks::$HOME/.claude/hooks::dir"
  ".claude/commands::$HOME/.claude/commands::dir"

  # ~/.agents — same per-file + per-subdir pattern
  ".agents/.skill-lock.json::$HOME/.agents/.skill-lock.json::file"
  ".agents/skills::$HOME/.agents/skills::dir"
)

# macOS-only links
declare -a MACOS_ONLY_LINKS=(
  ".zshrc::$HOME/.zshrc::file"
  ".zsh::$HOME/.zsh::dir"
  ".config/aerospace::$HOME/.config/aerospace::dir"
  ".config/borders::$HOME/.config/borders::dir"
  ".config/ghostty::$HOME/.config/ghostty::dir"
  ".config/tmux::$HOME/.config/tmux::dir"
  ".config/tmux-sessionizer::$HOME/.config/tmux-sessionizer::dir"
  ".config/starship.toml::$HOME/.config/starship.toml::file"
)

if [[ "$OS_TYPE" == "macos" ]]; then
  LINKS+=("${MACOS_ONLY_LINKS[@]}")
fi

link_one() {
  local src_rel="$1" target="$2"
  local src="$REPO/$src_rel"

  if [ ! -e "$src" ]; then
    log_warn "Skipping $target — source missing: $src"
    return
  fi

  mkdir -p "$(dirname "$target")"

  if [ -L "$target" ]; then
    local current
    current="$(readlink "$target")"
    if [ "$current" = "$src" ]; then
      log_info "ok    $target"
      return
    fi
    log_info "relink $target (was -> $current)"
    rm "$target"
  elif [ -e "$target" ]; then
    local bak
    bak="$target.bak.$(date +%s)"
    log_warn "backup $target -> $bak"
    mv "$target" "$bak"
  fi

  ln -s "$src" "$target"
  log_success "link  $target -> $src"
}

log_info "Linking dotfiles from $REPO..."
for entry in "${LINKS[@]}"; do
  src_rel="${entry%%::*}"
  rest="${entry#*::}"
  target="${rest%%::*}"
  # mode="${rest#*::}"  # unused for now; kept in LINKS for future use
  link_one "$src_rel" "$target"
done

# Cross-package relative link: ~/.claude/skills -> ../.agents/skills.
# Resolves via ~/.agents/skills (itself a symlink into the repo) so Claude Code
# discovers every skill without per-skill maintenance.
skills_link="$HOME/.claude/skills"
skills_want="../.agents/skills"
if [ -L "$skills_link" ] && [ "$(readlink "$skills_link")" = "$skills_want" ]; then
  log_info "ok    $skills_link"
elif [ -d "$skills_link" ] && ! [ -L "$skills_link" ]; then
  # Old per-skill-link install left a real dir behind; only rmdir if empty.
  rmdir "$skills_link" 2>/dev/null || log_warn "$skills_link is a non-empty real dir; leaving it alone"
  if ! [ -e "$skills_link" ]; then
    ln -s "$skills_want" "$skills_link"
    log_success "link  $skills_link -> $skills_want"
  fi
else
  [ -L "$skills_link" ] && rm "$skills_link"
  ln -s "$skills_want" "$skills_link"
  log_success "link  $skills_link -> $skills_want"
fi

log_success "Dotfiles linked."

# Ensure ~/.zsh/private.zsh exists (empty) on macOS so .zshrc's source line is
# a no-op on first run instead of relying solely on the [ -r ] guard.
# Gitignored — ~/.zsh is symlinked into the repo.
if [[ "$OS_TYPE" == "macos" ]]; then
  PRIVATE_ZSH="$HOME/.zsh/private.zsh"
  if [ ! -e "$PRIVATE_ZSH" ]; then
    mkdir -p "$(dirname "$PRIVATE_ZSH")"
    : >"$PRIVATE_ZSH"
    log_success "created empty $PRIVATE_ZSH"
  else
    log_info "$PRIVATE_ZSH already exists, skipping..."
  fi
fi

# -----------------------------
# Select active Aerospace config (macOS only).
#
# AeroSpace reads ~/.config/aerospace/aerospace.toml; that dir is a whole-dir
# symlink into the repo, so we create a relative sibling symlink
# aerospace.toml -> <choice>.toml inside $REPO (gitignored — per-machine choice).
# Candidates are discovered dynamically (every *.toml except the link itself),
# so adding a new config needs no change here.
# -----------------------------
if [[ "$OS_TYPE" == "macos" ]]; then
  AEROSPACE_DIR="$REPO/.config/aerospace"
  AEROSPACE_LINK="$AEROSPACE_DIR/aerospace.toml"

  AERO_CONFIGS=()
  for f in "$AEROSPACE_DIR"/*.toml; do
    [ -e "$f" ] || continue
    base="$(basename "$f")"
    [ "$base" = "aerospace.toml" ] && continue
    AERO_CONFIGS+=("$base")
  done

  if ((${#AERO_CONFIGS[@]} == 0)); then
    log_warn "No aerospace *.toml configs in $AEROSPACE_DIR; skipping."
  else
    current=""
    [ -L "$AEROSPACE_LINK" ] && current="$(readlink "$AEROSPACE_LINK")"

    log_info "Select Aerospace config:"
    default_idx=1
    for i in "${!AERO_CONFIGS[@]}"; do
      n=$((i + 1))
      mark=""
      [ "${AERO_CONFIGS[$i]}" = "$current" ] && {
        mark=" (current)"
        default_idx=$n
      }
      printf "  %d) %s%s\n" "$n" "${AERO_CONFIGS[$i]}" "$mark"
    done

    printf "%b[setup]%b Choice [1-%d] (default %d): " "$BLUE" "$RESET" "${#AERO_CONFIGS[@]}" "$default_idx"
    read -r AERO_CHOICE
    AERO_CHOICE="${AERO_CHOICE:-$default_idx}"
    if [[ "$AERO_CHOICE" =~ ^[0-9]+$ ]] && ((AERO_CHOICE >= 1 && AERO_CHOICE <= ${#AERO_CONFIGS[@]})); then
      AERO_TARGET="${AERO_CONFIGS[$((AERO_CHOICE - 1))]}"
    else
      AERO_TARGET="${AERO_CONFIGS[$((default_idx - 1))]}"
      log_warn "Invalid choice '$AERO_CHOICE'; using $AERO_TARGET."
    fi

    if [ -L "$AEROSPACE_LINK" ]; then
      rm "$AEROSPACE_LINK"
    elif [ -e "$AEROSPACE_LINK" ]; then
      bak="$AEROSPACE_LINK.bak.$(date +%s)"
      log_warn "backup $AEROSPACE_LINK -> $bak"
      mv "$AEROSPACE_LINK" "$bak"
    fi
    ln -s "$AERO_TARGET" "$AEROSPACE_LINK"
    log_success "aerospace.toml -> $AERO_TARGET"
  fi
fi

if [[ "$OS_TYPE" == "macos" ]]; then
  log_info "Applying MacOS defaults..."
  # https://macos-defaults.com

  # Set screenshots location
  defaults write com.apple.screencapture location -string "$HOME/Desktop/screenshots"
  # Automatically empty bin after 30 days
  defaults write com.apple.finder "FXRemoveOldTrashItems" -bool true
  # Show hidden files in Finder
  defaults write com.apple.finder AppleShowAllFiles -bool true
  # Show all filename extensions in Finder
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  # Show path bar in Finder
  defaults write com.apple.finder ShowPathbar -bool true
  # List view by default in Finder
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
  # Show the app switcher on all displays
  defaults write com.apple.dock appswitcher-all-displays -bool true
  # Disable press-and-hold for keys in favor of key repeat
  defaults write -g ApplePressAndHoldEnabled -bool false
  # Set click weight to light
  defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 0
  # Do not automatically rearrange Spaces based on most recent use
  defaults write com.apple.dock mru-spaces -bool false
  # Group windows by application in Mission Control
  defaults write com.apple.dock expose-group-apps -bool true
  defaults write com.apple.dock expose-group-by-app -bool true
  # Set Dock to auto-hide
  defaults write com.apple.dock autohide -bool true
  # Put Dock on the left
  defaults write com.apple.dock orientation -string "left"
  # Do not show recent applications in Dock
  defaults write com.apple.dock show-recents -bool false
  # Show only active apps in Dock
  defaults write com.apple.dock static-only -bool true
  # Set the icon size of Dock items to 36 pixels
  defaults write com.apple.dock tilesize -int 36

  killall Finder
  killall Dock
  killall SystemUIServer

  log_success "MacOS defaults applied."
fi

log_success "Everything done!"
