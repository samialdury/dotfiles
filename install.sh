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
  OS_TYPE="arch"
else
  log_error "Unsupported OS. This script only supports macOS and Arch Linux."
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
arch)
  if ! command -v pacman >/dev/null 2>&1; then
    log_error "pacman not found. This does not look like a real Arch system."
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
  log_warn "Before running this script, you *must* fully update your Arch system:"
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
  ["fish"]="fish"
  ["lazygit"]="lazygit"
  ["nvim"]="neovim"
  ["starship"]="starship"
  ["stow"]="stow"
  ["tmux"]="tmux"
  ["rg"]="ripgrep"
  ["fd"]="fd"
  ["fzf"]="fzf"
)

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
  arch)
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
# Install tmux TPM
# -----------------------------
TPM_DIR="$HOME/.tmux/plugins/tpm"

if [ ! -d "$TPM_DIR" ]; then
  log_info "Installing tmux TPM..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  log_success "tmux TPM installed."
else
  log_info "tmux TPM already exists, skipping..."
fi

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
# Stow dotfiles
# -----------------------------
declare -a STOW_DIRS=(
  "bat"
  "fish"
  "ghostty"
  "home"
  "lazygit"
  "nvim"
  "ssh"
  "starship"
  "tmux"
)

log_info "Stowing dotfiles..."

for dir in "${STOW_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    log_info "Stowing $dir..."
    stow "$dir"
    log_success "Stowed $dir"
  else
    log_warn "Skipping $dir — directory not found"
  fi
done

log_success "Configuration files installed."

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
