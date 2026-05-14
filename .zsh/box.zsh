# Tailscale + SSH/mosh helpers for the home box.
# Ported from .bash/box.bash.

export BOX_USER=sami
export BOX_HOST=REDACTED-HOST
export BOX_MAC=REDACTED-MAC
export BOX_GATEWAY_USER=root
export BOX_GATEWAY_HOST=REDACTED-HOST

_box_check_tailscale() {
  if ! command -v tailscale >/dev/null 2>&1; then
    echo "tailscale CLI not found in PATH."
    return 1
  fi
  if ! tailscale status >/dev/null 2>&1; then
    echo "Tailscale is not running. Start the Tailscale app and try again."
    return 1
  fi
}

_box_ssh_check() {
  ssh -o ConnectTimeout=2 -o BatchMode=yes "$BOX_USER@$BOX_HOST" command -v mosh-server >/dev/null 2>&1
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

  local raw session
  raw="$(scutil --get LocalHostName)"
  session="${raw//[^a-zA-Z0-9-]/-}"
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
  local cmd="${1:-up}"
  shift 2>/dev/null || true
  case "$cmd" in
    up) _box_up ;;
    down) _box_down ;;
    ssh) _box_ssh "$@" ;;
    status) _box_status ;;
    -h|--help|help)
      echo "usage: box [up|down|ssh [args...]|status]"
      ;;
    *)
      echo "box: unknown subcommand '$cmd'"
      echo "usage: box [up|down|ssh [args...]|status]"
      return 1
      ;;
  esac
}
