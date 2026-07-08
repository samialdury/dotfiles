# Package-manager helpers. Sourced by install.sh.

install_pacman_packages() {
  local -n packages_ref="$1"
  local cmd

  for cmd in "${!packages_ref[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      log_info "Installing package: ${packages_ref[$cmd]}"
      sudo pacman -S --needed --noconfirm "${packages_ref[$cmd]}"
      log_success "Finished installing: ${packages_ref[$cmd]}"
    else
      log_info "$cmd already installed, skipping..."
    fi
  done
}

install_apt_packages() {
  local -n packages_ref="$1"
  local cmd package
  local -a missing_packages=()

  for cmd in "${!packages_ref[@]}"; do
    package="${packages_ref[$cmd]}"
    if command -v "$cmd" >/dev/null 2>&1; then
      log_info "$cmd already installed, skipping..."
    else
      missing_packages+=("$package")
    fi
  done

  if ((${#missing_packages[@]} == 0)); then
    log_success "APT packages satisfied."
    return
  fi

  log_info "Installing APT packages: ${missing_packages[*]}"
  sudo apt-get install -y "${missing_packages[@]}"
  log_success "APT packages installed."
}

install_apt_package_if_available() {
  local cmd="$1" package="$2"

  if command -v "$cmd" >/dev/null 2>&1; then
    log_info "$cmd already installed, skipping..."
    return
  fi

  if apt-cache show "$package" >/dev/null 2>&1; then
    log_info "Installing package: $package"
    sudo apt-get install -y "$package"
    log_success "Finished installing: $package"
  else
    log_warn "$package is not available via APT on this system; install $cmd manually if needed."
  fi
}

install_apt_package_if_missing() {
  local package="$1"

  if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"; then
    log_info "$package already installed, skipping..."
    return
  fi

  if apt-cache show "$package" >/dev/null 2>&1; then
    log_info "Installing package: $package"
    sudo apt-get install -y "$package"
    log_success "Finished installing: $package"
  else
    log_warn "$package is not available via APT on this system; skipping."
  fi
}
