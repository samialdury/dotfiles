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

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=install/lib.sh
. "$REPO/install/lib.sh"
# shellcheck source=install/packages.sh
. "$REPO/install/packages.sh"
# shellcheck source=install/links.sh
. "$REPO/install/links.sh"
# shellcheck source=install/shell.sh
. "$REPO/install/shell.sh"
# shellcheck source=install/tmux.sh
. "$REPO/install/tmux.sh"
# shellcheck source=install/macos.sh
. "$REPO/install/macos.sh"
# shellcheck source=install/debian.sh
. "$REPO/install/debian.sh"

require_bash4

detect_os
log_info "Detected OS: $OS_TYPE"

platform_preconditions
configure_git_hooks
platform_install_packages
install_tmux_sessionizer
build_links
apply_links
link_claude_skills
platform_setup_shell
platform_post_install

log_success "Everything done!"
