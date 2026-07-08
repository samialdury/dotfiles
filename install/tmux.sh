# tmux-sessionizer installer. Sourced by install.sh.

install_tmux_sessionizer() {
  local ts_bin="$HOME/.local/scripts/tmux-sessionizer"
  local tmpdir

  if command -v tmux-sessionizer >/dev/null 2>&1 || [ -x "$ts_bin" ]; then
    log_info "tmux-sessionizer already installed, skipping..."
    return
  fi

  if ! command -v git >/dev/null 2>&1; then
    log_warn "Skipping tmux-sessionizer — git is not installed."
    return
  fi

  log_info "Installing tmux-sessionizer..."
  tmpdir="$(mktemp -d)"
  if ! git clone https://github.com/ThePrimeagen/tmux-sessionizer.git "$tmpdir"; then
    rm -rf "$tmpdir"
    return 1
  fi

  mkdir -p "$HOME/.local/scripts"
  mv "$tmpdir/tmux-sessionizer" "$ts_bin"
  chmod +x "$ts_bin"
  rm -rf "$tmpdir"

  log_success "tmux-sessionizer installed."
  log_warn "Make sure \$HOME/.local/scripts is in your PATH."
}
