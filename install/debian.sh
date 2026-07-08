# Debian platform implementation. Sourced by install.sh.

debian_preconditions() {
  if ! command -v apt-get >/dev/null 2>&1; then
    log_error "apt-get not found. This does not look like a Debian system."
    exit 1
  fi

  confirm_updated_system DOTFILES_DEBIAN_UPDATED "sudo apt-get update && sudo apt-get upgrade"
}

debian_install_packages() {
  declare -A packages=(
    ["zsh"]="zsh"
    ["git"]="git"
    ["batcat"]="bat"
    ["fdfind"]="fd-find"
    ["rg"]="ripgrep"
    ["nvim"]="neovim"
    ["tmux"]="tmux"
    ["fzf"]="fzf"
    ["jq"]="jq"
  )

  install_apt_packages packages
  install_apt_package_if_available delta git-delta
  install_apt_package_if_available zoxide zoxide
  install_apt_package_if_missing zsh-autosuggestions
  install_apt_package_if_missing zsh-syntax-highlighting
  install_apt_package_if_available starship starship
}

debian_add_links() {
  append_links \
    "${LINKS_BASE[@]}" \
    "${LINKS_AI[@]}" \
    "${LINKS_SHARED_CLI[@]}" \
    "${LINKS_ZSH[@]}"
}

debian_setup_shell() {
  ensure_private_zsh
  ensure_login_shell "/usr/bin/zsh"
}

debian_create_cli_wrappers() {
  mkdir -p "$HOME/.local/bin"

  if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    log_success "link  $HOME/.local/bin/bat -> $(command -v batcat)"
  fi

  if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    log_success "link  $HOME/.local/bin/fd -> $(command -v fdfind)"
  fi
}

debian_post_install() {
  debian_create_cli_wrappers
}
