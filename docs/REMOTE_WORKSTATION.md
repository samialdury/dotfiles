# Remote Workstation: WoL + Mosh + Tmux via Tailscale

Wake-on-LAN, persistent terminal sessions, and graceful remote shutdown for a self-hosted dev workstation. Architected around three machines: a thin client (Mac), an always-on gateway (Pi), and the actual workhorse (PN53).

> Inspired by [Tailscale's blog post on Wake-on-LAN with UpSnap](https://tailscale.com/blog/wake-on-lan-tailscale-upsnap). This guide takes a more minimal approach using a small fish function on the client and a single SSH hop through a Pi acting as the LAN gateway, with no additional self-hosted services.

## Architecture

```
Mac (anywhere)
    │
    ├──── Tailscale ────► Pi (always on, home LAN)
    │                       │
    │                       └── magic packet (LAN broadcast) ──► PN53 NIC
    │                                                              │
    │                                                              ▼
    │                                                          [boot + LUKS auto-unlock]
    │                                                              │
    └──── Tailscale ──── mosh ────────────────────────────► PN53 (tmux session)
```

The Mac cannot send the WoL magic packet directly because magic packets are L2 broadcasts that don't traverse Tailscale. The Pi sits on the home LAN and acts as the broadcast accomplice. Once the PN53 boots, the Mac connects to it directly over Tailscale via mosh into a per-client tmux session.

## Hardware

- **Mac client:** any modern Mac
- **Pi gateway:** any Raspberry Pi on the home LAN, always on, on Tailscale
- **PN53 workhorse:** ASUS PN53 mini PC (or equivalent). Wired Ethernet required; WiFi WoL is unreliable on Linux.

## Dependencies by Machine

| Machine | Required |
|---|---|
| Mac | `mosh`, `tailscale` (CLI in PATH), fish shell, SSH key |
| Pi | `wakeonlan`, Tailscale, OpenSSH server |
| PN53 | `ethtool`, `tmux`, `mosh`, `tailscale`, `clevis`, `tpm2-tools`, `tpm2-tss`, `mkinitcpio-clevis-hook` (AUR) |

---

## Part 1: PN53 BIOS Configuration

Boot the PN53 with a monitor and keyboard attached. Press **F2** (or **Del**) repeatedly during boot to enter BIOS.

1. Press **F7** to enter Advanced Mode.
2. Navigate to **Advanced → APM Configuration**.
3. Set the following:
   - `ErP Ready` → **Disabled** (keeps NIC powered in S5 so it can listen for magic packets)
   - `Restore AC Power Loss` → **Power On** (auto-boot after outage; optional)
   - `Power On By PCI-E` → **Enabled** (the actual WoL toggle)
4. Press **F10** to save and exit.

Also confirm TPM 2.0 (fTPM) is enabled in BIOS, which is required for LUKS auto-unlock later.

## Part 2: Enable WoL on Linux (PN53)

After booting back into Omarchy:

```bash
# Install ethtool
sudo pacman -S ethtool

# Identify your wired interface (usually enpXsY, not wlan*)
ip -br link

# Replace enp2s0 with your interface throughout
sudo ethtool -s enp2s0 wol g
sudo ethtool enp2s0 | grep Wake-on   # should show: Wake-on: g
```

Persist across reboots with a systemd unit:

```bash
sudo tee /etc/systemd/system/wol.service > /dev/null <<'EOF'
[Unit]
Description=Enable Wake-on-LAN on enp2s0
Requires=network.target
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/ethtool -s enp2s0 wol g

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now wol.service
systemctl status wol.service
```

Note the wired MAC address from `ip link show enp2s0`. You'll need it for the Pi.

## Part 3: TPM Auto-Unlock for LUKS (Omarchy)

By default Omarchy's full-disk encryption blocks boot at the LUKS passphrase prompt, which defeats remote wake. Bind LUKS to the TPM so the disk auto-unlocks on boot.

**Tradeoff:** anyone with physical access can boot the machine (your user login is still required). Acceptable for a home server, not for a stolen-laptop threat model.

> Steps below are condensed from the [official Omarchy discussion: Using Clevis with TPM2 for Auto-Unlock](https://github.com/basecamp/omarchy/discussions/1283). Refer to that thread for the full rationale and edge cases.

```bash
# Install dependencies
sudo pacman -S --needed clevis tpm2-tools tpm2-tss
yay -S --needed mkinitcpio-clevis-hook

# Identify the LUKS partition (the parent of the row with TYPE=crypt)
lsblk
# Example: /dev/nvme0n1p2

# Bind LUKS to TPM2 (will prompt for current LUKS passphrase)
sudo clevis luks bind -d /dev/nvme0n1p2 tpm2 '{}'
sudo clevis luks list -d /dev/nvme0n1p2  # should list a tpm2 entry

# Add 'clevis' before 'encrypt' in the HOOKS line
# Omarchy uses a drop-in config:
sudo sed -i -E '/^HOOKS=.*\bclevis\b/! s/^(HOOKS=\([^)]*)\bencrypt/\1 clevis encrypt/' \
  /etc/mkinitcpio.conf.d/omarchy_hooks.conf

# Verify
grep HOOKS /etc/mkinitcpio.conf.d/omarchy_hooks.conf

# Rebuild initramfs (Omarchy uses Limine bootloader + UKI)
sudo mkinitcpio -P
# When prompted to run limine-mkinitcpio, answer Y

sudo reboot
```

If reboot proceeds straight to the login screen with no passphrase prompt, success. Your existing passphrase still works as a fallback if the TPM measurements ever change (firmware updates, BIOS settings).

## Part 4: PN53 Server-Side Hooks

```bash
# Install tmux and mosh
sudo pacman -S tmux mosh

# Enable Tailscale SSH (centralizes auth via tailnet)
sudo tailscale set --ssh

# Allow passwordless poweroff for non-interactive remote shutdown
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl poweroff" | \
  sudo tee /etc/sudoers.d/poweroff

# Optional: shorthand alias inside the shell
echo "alias bye='sudo systemctl poweroff'" >> ~/.bashrc
```

## Part 5: Pi Gateway Setup

The Pi only needs to receive an SSH command from the Mac and broadcast a magic packet on the LAN.

```bash
# On the Pi
sudo apt update
sudo apt install wakeonlan

# Verify it can reach the PN53's NIC by MAC
# (replace with the PN53 MAC noted earlier)
wakeonlan e8:9c:25:8a:f3:2b
```

Make sure the Pi is on Tailscale and reachable by hostname (e.g., `yamipi`).

## Part 6: Mac Client Setup

```bash
# Install dependencies
brew install mosh

# Tailscale CLI in PATH (App Store version only)
sudo ln -s "/Applications/Tailscale.app/Contents/MacOS/Tailscale" /usr/local/bin/tailscale

# SSH key auth (one-time, eliminates password prompts)
ls ~/.ssh/id_ed25519.pub 2>/dev/null || ssh-keygen -t ed25519
ssh-copy-id sami@yamipi
ssh-copy-id sami@omarchypn
```

### Fish Functions

Save as `~/.config/fish/conf.d/box.fish`. Update the five variables at the top to match your setup:

```fish
# ~/.config/fish/conf.d/box.fish

set -gx BOX_USER sami
set -gx BOX_HOST omarchypn
set -gx BOX_MAC e8:9c:25:8a:f3:2b
set -gx BOX_GATEWAY_USER sami
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
```

**Why the SSH-based readiness check instead of `nc`?** `nc -z` succeeds the moment sshd binds to port 22, which happens early in boot before the user shell and PATH are ready. Probing with `ssh ... command -v mosh-server` confirms the system is fully initialized AND mosh-server is reachable. If that returns 0, mosh will work. `BatchMode=yes` prevents password hangs and `ConnectTimeout=2` makes failed attempts fail fast.

## Daily Workflow

```fish
box           # idempotent: wakes if off, attaches mosh+tmux either way (alias for `box up`)
# work in nvim, docker, etc.
# Ctrl-b d    to detach (keep tasks running, machine stays on)
bye           # inside the session: full shutdown
# or `box down` from the Mac when not in a session
box ssh ls    # plain ssh (no mosh/tmux); forwards extra args to ssh
box status    # check reachability without attaching; exit 0 = up, 1 = down
```

### What you get for free

- **Close laptop mid-work:** mosh suspends, tmux keeps running on the PN53. Reopen later, mosh reconnects to the same session.
- **Switch networks:** mosh follows you from home WiFi to coffee shop to hotspot.
- **Mosh dies entirely:** run `box` again, you reattach to the same tmux session.
- **Multiple clients:** each Mac/iPad/phone gets its own tmux session named after the client hostname.

## Troubleshooting

**WoL packet sent but PN53 doesn't boot.**
Check the switch port LED stays lit after `poweroff`. If it goes dark, ErP is still cutting power to the NIC. Re-verify BIOS settings.

**PN53 boots but Tailscale shows offline / SSH fails.**
Likely the LUKS passphrase prompt is blocking boot. Plug in a monitor to confirm. If yes, redo Part 3.

**`box` reports "Did not find mosh server startup message".**
Race condition: sshd accepted the connection before the user shell was fully initialized. The SSH-based readiness check in the function (probing for `mosh-server` via `ssh ... command -v mosh-server`) prevents this. If you previously used a `nc -z` probe, replace it with the SSH version shown above.

**Probes hang forever.**
If you're using a `nc`-based check on macOS, BSD `nc` waits for the kernel TCP timeout (~75s) without `-G 1`. The SSH-based check (`ConnectTimeout=2 BatchMode=yes`) avoids this entirely.

**`ssh yamipi` prompts for password.**
SSH keys aren't installed on the Pi. Run `ssh-copy-id sami@yamipi`.

**TPM unlock fails after firmware update.**
Expected. Boot once with the LUKS passphrase, then re-run `clevis luks bind` to re-enroll against the new TPM measurements.

**Bash history not appearing in scp copy.**
Bash only writes history on shell exit. Run `history -a` in the source session first to flush, then copy.

## External References

- [Tailscale: Wake your computer remotely with Tailscale and UpSnap](https://tailscale.com/blog/wake-on-lan-tailscale-upsnap) — alternative WoL approach using UpSnap as a self-hosted web UI; useful background on the Tailscale + LAN-gateway pattern.
- [Omarchy Discussion #1283: Clevis + TPM2 Auto-Unlock](https://github.com/basecamp/omarchy/discussions/1283) — source for the LUKS auto-unlock steps in Part 3.
- [Arch Wiki: dm-crypt/System configuration](https://wiki.archlinux.org/title/Dm-crypt/System_configuration) — reference for `mkinitcpio` hooks and `crypttab` if your bootloader/initramfs setup differs from Omarchy's.
- [Arch Wiki: Wake-on-LAN](https://wiki.archlinux.org/title/Wake-on-LAN) — generic Linux WoL setup, useful if you're not on Omarchy.
- [ASUS: Enable WoL on Commercial DT/AIO/MiniPC](https://www.asus.com/support/faq/1048459/) — official BIOS steps for the PN53 and other ASUS mini PCs.
- [Mosh](https://mosh.org/) — project home, protocol overview, and why it survives roaming and sleep.

## Files Reference

| Path | Machine | Purpose |
|---|---|---|
| `/etc/systemd/system/wol.service` | PN53 | Persists `ethtool wol g` across reboots |
| `/etc/sudoers.d/poweroff` | PN53 | Passwordless shutdown for remote `poweroff` |
| `/etc/mkinitcpio.conf.d/omarchy_hooks.conf` | PN53 | Adds `clevis` hook for TPM unlock |
| `~/.config/fish/conf.d/box.fish` | Mac | Client-side wake/connect/shutdown functions |