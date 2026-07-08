# macOS platform implementation. Sourced by install.sh.

macos_preconditions() {
  if ! command -v brew >/dev/null 2>&1; then
    log_error "Homebrew not found. Install it from https://brew.sh"
    exit 1
  fi

  local brewfile="$REPO/Brewfile"
  if [ ! -f "$brewfile" ]; then
    log_error "Brewfile missing at $brewfile"
    exit 1
  fi

  log_info "Checking Brewfile state: $brewfile"
  if ! brew bundle check --file="$brewfile" >/dev/null 2>&1; then
    log_warn "Brewfile not fully installed. Continuing anyway."
    log_warn "To install missing packages, run:"
    log_warn "  brew update && brew bundle install --file=$brewfile"
  else
    log_success "Brewfile satisfied."
  fi
}

macos_install_packages() {
  : # Brewfile is the macOS package source of truth; this script only checks it.
}

macos_add_links() {
  append_links \
    "${LINKS_BASE[@]}" \
    "${LINKS_AI[@]}" \
    "${LINKS_SHARED_CLI[@]}" \
    "${LINKS_ZSH[@]}" \
    "${LINKS_MAC_GUI[@]}" \
    "${LINKS_MAC_EXTRA[@]}"
}

macos_setup_shell() {
  ensure_login_shell "/opt/homebrew/bin/zsh"
  ensure_private_zsh
}

macos_select_aerospace_config() {
  local aerospace_dir="$REPO/.config/aerospace"
  local aerospace_link="$aerospace_dir/aerospace.toml"
  local current default_idx aero_choice aero_target base n mark
  local -a aero_configs=()

  for f in "$aerospace_dir"/*.toml; do
    [ -e "$f" ] || continue
    base="$(basename "$f")"
    [ "$base" = "aerospace.toml" ] && continue
    aero_configs+=("$base")
  done

  if ((${#aero_configs[@]} == 0)); then
    log_warn "No aerospace *.toml configs in $aerospace_dir; skipping."
    return
  fi

  current=""
  [ -L "$aerospace_link" ] && current="$(readlink "$aerospace_link")"

  if [ ! -t 0 ]; then
    if [ -n "$current" ]; then
      log_info "Non-interactive shell; keeping current aerospace.toml -> $current"
      return
    fi
    aero_target="${aero_configs[0]}"
    log_warn "Non-interactive shell; selecting default Aerospace config: $aero_target"
  else
    log_info "Select Aerospace config:"
    default_idx=1
    for i in "${!aero_configs[@]}"; do
      n=$((i + 1))
      mark=""
      [ "${aero_configs[$i]}" = "$current" ] && {
        mark=" (current)"
        default_idx=$n
      }
      printf "  %d) %s%s\n" "$n" "${aero_configs[$i]}" "$mark"
    done

    printf "%b[setup]%b Choice [1-%d] (default %d): " "$BLUE" "$RESET" "${#aero_configs[@]}" "$default_idx"
    read -r aero_choice
    aero_choice="${aero_choice:-$default_idx}"
    if [[ "$aero_choice" =~ ^[0-9]+$ ]] && ((aero_choice >= 1 && aero_choice <= ${#aero_configs[@]})); then
      aero_target="${aero_configs[$((aero_choice - 1))]}"
    else
      aero_target="${aero_configs[$((default_idx - 1))]}"
      log_warn "Invalid choice '$aero_choice'; using $aero_target."
    fi
  fi

  if [ -L "$aerospace_link" ]; then
    rm "$aerospace_link"
  elif [ -e "$aerospace_link" ]; then
    local bak="$aerospace_link.bak.$(date +%s)"
    log_warn "backup $aerospace_link -> $bak"
    mv "$aerospace_link" "$bak"
  fi
  ln -s "$aero_target" "$aerospace_link"
  log_success "aerospace.toml -> $aero_target"
}

macos_apply_defaults() {
  log_info "Applying MacOS defaults..."

  defaults write com.apple.screencapture location -string "$HOME/Desktop/screenshots"
  defaults write com.apple.finder "FXRemoveOldTrashItems" -bool true
  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
  defaults write com.apple.dock appswitcher-all-displays -bool true
  defaults write -g ApplePressAndHoldEnabled -bool false
  defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 0
  defaults write com.apple.dock mru-spaces -bool false
  defaults write com.apple.dock expose-group-apps -bool true
  defaults write com.apple.dock expose-group-by-app -bool true
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock orientation -string "left"
  defaults write com.apple.dock show-recents -bool false
  defaults write com.apple.dock static-only -bool true
  defaults write com.apple.dock tilesize -int 36

  killall Finder 2>/dev/null || true
  killall Dock 2>/dev/null || true
  killall SystemUIServer 2>/dev/null || true

  log_success "MacOS defaults applied."
}

macos_post_install() {
  macos_select_aerospace_config
  macos_apply_defaults
}
