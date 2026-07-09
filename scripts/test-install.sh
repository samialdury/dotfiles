#!/usr/bin/env bash

# Match install.sh's Bash 4+ requirement without installing anything.
if ((BASH_VERSINFO[0] < 4)); then
  if [ -x /opt/homebrew/bin/bash ]; then
    exec /opt/homebrew/bin/bash "$0" "$@"
  fi

  printf 'error: %s requires Bash 4+. Install Homebrew bash or run through ./install.sh first.\n' "$0" >&2
  exit 1
fi
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

pass() {
  printf 'ok %s\n' "$*"
}

fail() {
  printf 'not ok %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local needle="$1"
  shift

  local item
  for item in "$@"; do
    if [ "$item" = "$needle" ]; then
      return 0
    fi
  done

  fail "expected profile to contain $needle"
}

assert_not_contains() {
  local needle="$1"
  shift

  local item
  for item in "$@"; do
    if [ "$item" = "$needle" ]; then
      fail "expected profile to exclude $needle"
    fi
  done
}

assert_path_absent() {
  local path="$1"

  if [ -e "$REPO/$path" ] || [ -L "$REPO/$path" ]; then
    fail "unexpected shell config should not be tracked: $path"
  fi
}

link_sources() {
  local entry
  for entry in "${LINKS[@]}"; do
    printf '%s\n' "${entry%%::*}"
  done
}

build_profile() {
  local platform="$1"
  OS_TYPE="$platform"
  build_links
}

# shellcheck source=../install/lib.sh
. "$REPO/install/lib.sh"
# shellcheck source=../install/packages.sh
. "$REPO/install/packages.sh"
# shellcheck source=../install/links.sh
. "$REPO/install/links.sh"
# shellcheck source=../install/shell.sh
. "$REPO/install/shell.sh"
# shellcheck source=../install/tmux.sh
. "$REPO/install/tmux.sh"
# shellcheck source=../install/macos.sh
. "$REPO/install/macos.sh"
# shellcheck source=../install/omarchy.sh
. "$REPO/install/omarchy.sh"
# shellcheck source=../install/debian.sh
. "$REPO/install/debian.sh"

bash -n "$REPO/install.sh" "$REPO"/install/*.sh "$REPO/.githooks/pre-commit" "$REPO/.claude/statusline-command.sh" "$REPO/scripts/test-install.sh"
pass "bash syntax"

if command -v zsh >/dev/null 2>&1; then
  zsh -n "$REPO/.zshrc" "$REPO"/.zsh/*.zsh
  pass "zsh syntax"
else
  pass "zsh syntax skipped: zsh not installed"
fi

assert_path_absent ".bashrc"
assert_path_absent ".bash_profile"
assert_path_absent ".bash"
assert_path_absent ".inputrc"
pass "shell config guard"

build_profile macos
mapfile -t macos_sources < <(link_sources)
assert_contains ".claude/settings.json" "${macos_sources[@]}"
assert_contains ".zshrc" "${macos_sources[@]}"
assert_contains ".config/ghostty" "${macos_sources[@]}"
assert_contains ".config/aerospace" "${macos_sources[@]}"
assert_contains ".config/homebrew" "${macos_sources[@]}"
pass "macos link profile"

build_profile omarchy
mapfile -t omarchy_sources < <(link_sources)
assert_contains ".claude/settings.json" "${omarchy_sources[@]}"
assert_contains ".config/workmux" "${omarchy_sources[@]}"
assert_contains ".config/nvim" "${omarchy_sources[@]}"
assert_not_contains ".zshrc" "${omarchy_sources[@]}"
assert_not_contains ".config/tmux" "${omarchy_sources[@]}"
assert_not_contains ".config/starship.toml" "${omarchy_sources[@]}"
assert_not_contains ".config/ghostty" "${omarchy_sources[@]}"
assert_not_contains ".config/aerospace" "${omarchy_sources[@]}"
pass "omarchy link profile"

build_profile debian
mapfile -t debian_sources < <(link_sources)
assert_contains ".claude/settings.json" "${debian_sources[@]}"
assert_contains ".zshrc" "${debian_sources[@]}"
assert_contains ".zsh" "${debian_sources[@]}"
assert_contains ".config/tmux" "${debian_sources[@]}"
assert_contains ".config/starship.toml" "${debian_sources[@]}"
assert_contains ".config/workmux" "${debian_sources[@]}"
assert_not_contains ".config/ghostty" "${debian_sources[@]}"
assert_not_contains ".config/aerospace" "${debian_sources[@]}"
assert_not_contains ".config/homebrew" "${debian_sources[@]}"
pass "debian link profile"
