# Tailscale + SSH/mosh helpers for the home box.
# BOX_USER / BOX_HOST / BOX_MAC / BOX_GATEWAY_USER / BOX_GATEWAY_HOST are
# machine-local identifiers; set them in ~/.zsh/private.zsh (gitignored).

_box_check_tailscale() {
  if ! command -v tailscale >/dev/null 2>&1; then
    echo "tailscale CLI not found in PATH."
    return 1
  fi
  if ! tailscale status >/dev/null 2>&1; then
    echo "Tailscale is not running. Start Tailscale and try again."
    return 1
  fi
}

_box_ssh_check() {
  ssh -o ConnectTimeout=2 -o BatchMode=yes "$BOX_USER@$BOX_HOST" command -v mosh-server >/dev/null 2>&1
}

_box_session_name() {
  local raw

  if command -v scutil >/dev/null 2>&1; then
    raw="$(scutil --get LocalHostName 2>/dev/null || true)"
  fi
  raw="${raw:-$(hostname -s 2>/dev/null || hostname)}"
  echo "${raw//[^a-zA-Z0-9-]/-}"
}

_box_up() {
  _box_check_tailscale || return

  if ! _box_ssh_check; then
    ssh "$BOX_GATEWAY_USER@$BOX_GATEWAY_HOST" "wakeonlan $BOX_MAC"
    echo "Waking..."
    while ! _box_ssh_check; do
      sleep 1
    done
  fi

  local session
  session="$(_box_session_name)"
  mosh "$BOX_USER@$BOX_HOST" -- tmux new-session -A -s "$session"
}

_box_down() {
  _box_check_tailscale || return
  ssh "$BOX_USER@$BOX_HOST" "sudo systemctl poweroff"
}

_box_ssh() {
  _box_check_tailscale || return
  ssh "$BOX_USER@$BOX_HOST" "$@"
}

_box_status() {
  _box_check_tailscale || return
  if _box_ssh_check; then
    echo "$BOX_HOST: up"
  else
    echo "$BOX_HOST: down (or unreachable)"
    return 1
  fi
}

box() {
  if [ -z "$BOX_HOST" ] || [ -z "$BOX_GATEWAY_HOST" ]; then
    echo "box: set BOX_USER/BOX_HOST/BOX_MAC/BOX_GATEWAY_USER/BOX_GATEWAY_HOST in ~/.zsh/private.zsh" >&2
    return 1
  fi
  local cmd="${1:-up}"
  shift 2>/dev/null || true
  case "$cmd" in
  up) _box_up ;;
  down) _box_down ;;
  ssh) _box_ssh "$@" ;;
  status) _box_status ;;
  -h | --help | help)
    echo "usage: box [up|down|ssh [args...]|status]"
    ;;
  *)
    echo "box: unknown subcommand '$cmd'"
    echo "usage: box [up|down|ssh [args...]|status]"
    return 1
    ;;
  esac
}
