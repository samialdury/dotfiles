#!/usr/bin/env bash
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
# User must confirm updates (OS-aware)
# -----------------------------
if [[ "$OS_TYPE" == "macos" ]]; then
  UPDATE_CMD="brew update"
  log_warn "Before running this script, you *must* update Homebrew:"
else
  UPDATE_CMD="sudo pacman -Syu"
  log_warn "Before running this script, you *must* fully update your Omarchy system:"
fi

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

# -----------------------------
# Packages to install in format
# executable => package name
# -----------------------------
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

# -----------------------------
# Homebrew bash 5.x (macOS only)
#
# `command -v bash` resolves to system /bin/bash (3.2) on macOS, so the standard
# PACKAGES executable check doesn't work — special-case via brew prefix.
# -----------------------------
if [[ "$OS_TYPE" == "macos" ]]; then
  if ! [ -x /opt/homebrew/bin/bash ]; then
    log_info "Installing Homebrew bash 5.x..."
    brew install bash
    log_success "Homebrew bash installed."
  else
    log_info "Homebrew bash already installed, skipping..."
  fi
fi

declare -A MACOS_ONLY_PACKAGES=(
  ["ghostty"]="ghostty"
)

# Append macOS-only packages
if [[ "$OS_TYPE" == "macos" ]]; then
  for key in "${!MACOS_ONLY_PACKAGES[@]}"; do
    PACKAGES["$key"]="${MACOS_ONLY_PACKAGES[$key]}"
  done
fi

# -----------------------------
# Install package wrapper
# -----------------------------
install_pkg() {
  local pkg="$1"
  log_info "Installing package: $pkg"

  case "$OS_TYPE" in
  macos)
    brew install "$pkg"
    ;;
  omarchy)
    sudo pacman -S --needed --noconfirm "$pkg"
    ;;
  esac

  log_success "Finished installing: $pkg"
}

# -----------------------------
# Install required packages
# -----------------------------
for cmd in "${!PACKAGES[@]}"; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    install_pkg "${PACKAGES[$cmd]}"
  else
    log_info "$cmd already installed, skipping..."
  fi
done

# -----------------------------
# Install tmux-sessionizer
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

log_success "Install script finished."

# -----------------------------
# Set bash as default login shell (macOS only)
# -----------------------------
if [[ "$OS_TYPE" == "macos" ]]; then
  TARGET_SHELL="/opt/homebrew/bin/bash"
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
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Format per entry: "<src-relative-to-repo>::<target-absolute>::<mode>"
# Mode is informational only right now (file vs dir); link_one treats both the same.
declare -a LINKS=(
  # Flat $HOME files
  ".bashrc::$HOME/.bashrc::file"
  ".hushlogin::$HOME/.hushlogin::file"

  # ~/.bash — bash-side helpers (box.bash, etc.)
  ".bash::$HOME/.bash::dir"

  # ~/.config/<pkg> whole-dir links
  ".config/bat::$HOME/.config/bat::dir"
  ".config/git/config::$HOME/.config/git/config::file"
  ".config/lazygit::$HOME/.config/lazygit::dir"
  ".config/nvim::$HOME/.config/nvim::dir"

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
  ".bash_profile::$HOME/.bash_profile::file"
  ".inputrc::$HOME/.inputrc::file"
  ".config/ghostty::$HOME/.config/ghostty::dir"
  ".config/tmux::$HOME/.config/tmux::dir"
  ".config/opencode::$HOME/.config/opencode::dir"
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

if [[ "$OS_TYPE" == "macos" ]]; then
  log_info "Applying MacOS defaults..."
  # https://macos-defaults.com

  # Disable font smoothing
  defaults -currentHost write -g AppleFontSmoothing -int 0
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
