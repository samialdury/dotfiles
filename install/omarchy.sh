# Omarchy / Arch platform implementation. Sourced by install.sh.

omarchy_preconditions() {
  if ! command -v pacman >/dev/null 2>&1; then
    log_error "pacman not found. This does not look like a real Omarchy system."
    exit 1
  fi

  confirm_updated_system DOTFILES_OMARCHY_UPDATED "sudo pacman -Syu"
}

omarchy_install_packages() {
  declare -A packages=(
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
    ["jq"]="jq"
  )

  install_pacman_packages packages
}

omarchy_add_links() {
  # Omarchy keeps its installer-supplied shell config; do not link zsh here.
  append_links \
    "${LINKS_BASE[@]}" \
    "${LINKS_AI[@]}" \
    "${LINKS_SHARED_CLI[@]}"
}

omarchy_setup_shell() {
  : # Omarchy shell remains managed by Omarchy, not this repo.
}

omarchy_post_install() {
  :
}
