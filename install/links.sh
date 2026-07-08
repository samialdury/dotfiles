# Dotfile link groups and link helpers. Sourced by install.sh.

# Format per entry: "<src-relative-to-repo>::<target-absolute>::<mode>"
# Mode is informational only right now (file vs dir); link_one treats both the same.
declare -a LINKS=()

declare -a LINKS_BASE=(
  ".hushlogin::$HOME/.hushlogin::file"
  ".config/git/config::$HOME/.config/git/config::file"
)

declare -a LINKS_AI=(
  ".claude/settings.json::$HOME/.claude/settings.json::file"
  ".claude/statusline-command.sh::$HOME/.claude/statusline-command.sh::file"
  ".claude/agents::$HOME/.claude/agents::dir"
  ".claude/hooks::$HOME/.claude/hooks::dir"
  ".claude/commands::$HOME/.claude/commands::dir"
  ".agents/.skill-lock.json::$HOME/.agents/.skill-lock.json::file"
  ".agents/skills::$HOME/.agents/skills::dir"
)

declare -a LINKS_SHARED_CLI=(
  ".config/bat::$HOME/.config/bat::dir"
  ".config/lazygit::$HOME/.config/lazygit::dir"
  ".config/mise/config.toml::$HOME/.config/mise/config.toml::file"
  ".config/nvim::$HOME/.config/nvim::dir"
  ".config/workmux::$HOME/.config/workmux::dir"
)

declare -a LINKS_ZSH=(
  ".zshrc::$HOME/.zshrc::file"
  ".zsh::$HOME/.zsh::dir"
  ".config/tmux::$HOME/.config/tmux::dir"
  ".config/tmux-sessionizer::$HOME/.config/tmux-sessionizer::dir"
  ".config/starship.toml::$HOME/.config/starship.toml::file"
)

declare -a LINKS_MAC_GUI=(
  ".config/aerospace::$HOME/.config/aerospace::dir"
  ".config/borders::$HOME/.config/borders::dir"
  ".config/ghostty::$HOME/.config/ghostty::dir"
)

declare -a LINKS_MAC_EXTRA=(
  ".config/homebrew::$HOME/.config/homebrew::dir"
)

append_links() {
  LINKS+=("$@")
}

validate_links() {
  local entry src_rel rest target mode
  local -A targets=()

  for entry in "${LINKS[@]}"; do
    if [[ "$entry" != *::*::* ]]; then
      log_error "Invalid link entry; expected src::target::mode: $entry"
      exit 1
    fi

    src_rel="${entry%%::*}"
    rest="${entry#*::}"
    target="${rest%%::*}"
    mode="${rest#*::}"

    if [ -z "$src_rel" ]; then
      log_error "Invalid link entry with empty source: $entry"
      exit 1
    fi

    if [ -z "$target" ]; then
      log_error "Invalid link entry with empty target: $entry"
      exit 1
    fi

    case "$mode" in
    file | dir) ;;
    *)
      log_error "Invalid link mode '$mode' for $src_rel; expected file or dir."
      exit 1
      ;;
    esac

    if [ ! -e "$REPO/$src_rel" ]; then
      log_error "Link source missing for $target: $REPO/$src_rel"
      exit 1
    fi

    if [ -n "${targets[$target]+set}" ]; then
      log_error "Duplicate link target $target from $src_rel and ${targets[$target]}"
      exit 1
    fi

    targets[$target]="$src_rel"
  done
}

build_links() {
  LINKS=()
  platform_add_links
  validate_links
}

link_one() {
  local src_rel="$1" target="$2"
  local src="$REPO/$src_rel"

  if [ ! -e "$src" ]; then
    log_warn "Skipping $target — source missing: $src"
    return
  fi

  mkdir -p "$(dirname "$target")"

  if [ -L "$target" ]; then
    local current
    current="$(readlink "$target")"
    if [ "$current" = "$src" ]; then
      log_info "ok    $target"
      return
    fi
    log_info "relink $target (was -> $current)"
    rm "$target"
  elif [ -e "$target" ]; then
    local bak
    bak="$target.bak.$(date +%s)"
    log_warn "backup $target -> $bak"
    mv "$target" "$bak"
  fi

  ln -s "$src" "$target"
  log_success "link  $target -> $src"
}

apply_links() {
  local entry src_rel rest target

  log_info "Linking dotfiles from $REPO..."
  for entry in "${LINKS[@]}"; do
    src_rel="${entry%%::*}"
    rest="${entry#*::}"
    target="${rest%%::*}"
    # mode="${rest#*::}"  # unused for now; kept in link tables for future use
    link_one "$src_rel" "$target"
  done

  log_success "Dotfiles linked."
}

link_claude_skills() {
  local skills_link="$HOME/.claude/skills"
  local skills_want="../.agents/skills"

  if [ -L "$skills_link" ] && [ "$(readlink "$skills_link")" = "$skills_want" ]; then
    log_info "ok    $skills_link"
    return
  fi

  if [ -e "$skills_link" ] || [ -L "$skills_link" ]; then
    if [ -d "$skills_link" ] && ! [ -L "$skills_link" ]; then
      rmdir "$skills_link" 2>/dev/null || {
        log_warn "$skills_link is a non-empty real dir; leaving it alone"
        return
      }
    else
      local bak
      bak="$skills_link.bak.$(date +%s)"
      log_warn "backup $skills_link -> $bak"
      mv "$skills_link" "$bak"
    fi
  fi

  mkdir -p "$(dirname "$skills_link")"
  ln -s "$skills_want" "$skills_link"
  log_success "link  $skills_link -> $skills_want"
}
