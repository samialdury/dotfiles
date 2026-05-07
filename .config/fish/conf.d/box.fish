set -gx BOX_USER sami
set -gx BOX_HOST omarchypn
set -gx BOX_MAC e8:9c:25:8a:f3:2b
set -gx BOX_GATEWAY_USER root
set -gx BOX_GATEWAY_HOST yamipi

function _box_check_tailscale
    if not command -v tailscale >/dev/null
        echo "tailscale CLI not found in PATH."
        return 1
    end
    if not tailscale status >/dev/null 2>&1
        echo "Tailscale is not running. Start the Tailscale app and try again."
        return 1
    end
end

function _box_ssh_check
    ssh -o ConnectTimeout=2 -o BatchMode=yes $BOX_USER@$BOX_HOST command -v mosh-server >/dev/null 2>&1
end

function _box_up
    _box_check_tailscale; or return

    if not _box_ssh_check
        ssh $BOX_GATEWAY_USER@$BOX_GATEWAY_HOST "wakeonlan $BOX_MAC"
        echo "Waking..."
        while not _box_ssh_check
            sleep 1
        end
    end

    set -l session (scutil --get LocalHostName | string replace -ra '[^a-zA-Z0-9-]' '-')
    mosh $BOX_USER@$BOX_HOST -- tmux new-session -A -s $session
end

function _box_down
    _box_check_tailscale; or return
    ssh $BOX_USER@$BOX_HOST "sudo systemctl poweroff"
end

function _box_ssh
    _box_check_tailscale; or return
    ssh $BOX_USER@$BOX_HOST $argv
end

function _box_status
    _box_check_tailscale; or return
    if _box_ssh_check
        echo "$BOX_HOST: up"
    else
        echo "$BOX_HOST: down (or unreachable)"
        return 1
    end
end

function box
    set -l cmd $argv[1]
    test -z "$cmd"; and set cmd up
    set -l rest $argv[2..-1]
    switch $cmd
        case up
            _box_up
        case down
            _box_down
        case ssh
            _box_ssh $rest
        case status
            _box_status
        case -h --help help
            echo "usage: box [up|down|ssh [args...]|status]"
        case '*'
            echo "box: unknown subcommand '$cmd'"
            echo "usage: box [up|down|ssh [args...]|status]"
            return 1
    end
end
