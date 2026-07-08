# Shared installer helpers. Sourced by install.sh.

RESET='\033[0m'
BLUE='\033[34m'
YELLOW='\033[33m'
RED='\033[31m'
GREEN='\033[32m'

log_info() { printf "%b[setup][info]%b %s\n" "$BLUE" "$RESET" "$*"; }
log_warn() { printf "%b[setup][warn]%b %s\n" "$YELLOW" "$RESET" "$*"; }
log_error() { printf "%b[setup][error]%b %s\n" "$RED" "$RESET" "$*"; }
log_success() { printf "%b[setup][success]%b %s\n" "$GREEN" "$RESET" "$*"; }

require_bash4() {
  if ((BASH_VERSINFO[0] < 4)); then
    log_error "This script requires bash 4+. Install a newer bash and re-run."
    exit 1
  fi
}

detect_os() {
  if [ -n "${DOTFILES_OS:-}" ]; then
    case "$DOTFILES_OS" in
    macos | omarchy | debian)
      OS_TYPE="$DOTFILES_OS"
      return
      ;;
    *)
      log_error "Unsupported DOTFILES_OS=$DOTFILES_OS. Use macos, omarchy, or debian."
      exit 1
      ;;
    esac
  fi

  if [[ "${OSTYPE:-}" == darwin* ]]; then
    OS_TYPE="macos"
  elif [[ -f /etc/arch-release ]]; then
    OS_TYPE="omarchy"
  elif [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ "${ID:-}" == "debian" || "${ID_LIKE:-}" == *debian* ]]; then
      OS_TYPE="debian"
    else
      log_error "Unsupported Linux distribution: ${PRETTY_NAME:-unknown}."
      exit 1
    fi
  else
    log_error "Unsupported OS. This script supports macOS, Omarchy, and Debian."
    exit 1
  fi
}

is_yes() {
  case "${1,,}" in
  y | yes | 1 | true) return 0 ;;
  *) return 1 ;;
  esac
}

confirm_updated_system() {
  local env_var="$1" update_cmd="$2"

  if is_yes "${!env_var:-}"; then
    log_info "$env_var set; assuming system update was already run."
    return
  fi

  log_warn "Before running this script, you *must* fully update this system:"
  log_warn "  $update_cmd"

  if [ ! -t 0 ]; then
    log_error "Non-interactive shell. Re-run after '$update_cmd' or set $env_var=1."
    exit 1
  fi

  printf "%b[setup]%b Have you run '%s'? (y/yes to continue): " "$BLUE" "$RESET" "$update_cmd"
  read -r CONFIRM

  if ! is_yes "$CONFIRM"; then
    log_error "You must run '$update_cmd' before using this script. Exiting."
    exit 1
  fi

  log_info "Continuing..."
}

configure_git_hooks() {
  if command -v git >/dev/null 2>&1 && git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
    git -C "$REPO" config core.hooksPath .githooks
    log_success "Git hooks path configured."
  fi
}

platform_preconditions() {
  "${OS_TYPE}_preconditions"
}

platform_install_packages() {
  "${OS_TYPE}_install_packages"
}

platform_add_links() {
  "${OS_TYPE}_add_links"
}

platform_setup_shell() {
  "${OS_TYPE}_setup_shell"
}

platform_post_install() {
  "${OS_TYPE}_post_install"
}
