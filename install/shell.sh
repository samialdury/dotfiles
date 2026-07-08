# Login shell helpers. Sourced by install.sh.

ensure_login_shell() {
  local target_shell="$1"

  if [ ! -x "$target_shell" ]; then
    log_warn "Skipping chsh — $target_shell not present."
    return
  fi

  if ! grep -qx "$target_shell" /etc/shells; then
    log_warn "Adding $target_shell to /etc/shells (requires sudo)..."
    echo "$target_shell" | sudo tee -a /etc/shells >/dev/null
  fi

  if [[ "${SHELL:-}" != "$target_shell" ]]; then
    log_warn "Changing login shell to $target_shell (will prompt for password)..."
    chsh -s "$target_shell"
    log_success "Default shell set to $target_shell. Open a new terminal for it to take effect."
  else
    log_info "Default shell already $target_shell, skipping chsh..."
  fi
}

ensure_private_zsh() {
  local private_zsh="$HOME/.zsh/private.zsh"

  if [ ! -e "$private_zsh" ]; then
    mkdir -p "$(dirname "$private_zsh")"
    : >"$private_zsh"
    log_success "created empty $private_zsh"
  else
    log_info "$private_zsh already exists, skipping..."
  fi
}
