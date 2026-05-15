# dotfiles

This repository contains all my important dev environment configuration files.
It supports **MacOS** and **Omarchy** (Arch-based).

<!--toc:start-->
- [Installation](#installation)
- [Usage](#usage)
  - [MacOS — fresh-machine bootstrap](#macos--fresh-machine-bootstrap)
  - [Install script](#install-script)
- [Troubleshooting](#troubleshooting)
  - [SSH](#ssh)
- [Other](#other)
  - [Brew bundle](#brew-bundle)
  - [Gitleaks](#gitleaks)
- [License](#license)
<!--toc:end-->

## Installation

Generate a fresh SSH key for this machine and add it to your GitHub account.
Use a strong passphrase.
Never copy SSH private keys between machines — each host gets its own key.

```sh
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "$(hostname)" -f ~/.ssh/id_ed25519

# copy pub key to clipboard (macOS or Wayland) — paste into https://github.com/settings/keys
cat ~/.ssh/id_ed25519.pub | $(command -v wl-copy || command -v pbcopy)

eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519 # macOS
# ssh-add ~/.ssh/id_ed25519                    # Omarchy / Linux

# test connection
ssh -T git@github.com
```

```sh
git clone git@github.com:samialdury/dotfiles.git ~/dotfiles
```

## Usage

### MacOS — fresh-machine bootstrap

Step-by-step for a brand new MacBook. Most install steps are safe to re-run;
SSH key generation should be done intentionally.

```sh
# 1. macOS first-boot: sign into iCloud, sign into your password manager.

# 2. Install Xcode command line tools (provides git, clang, make).
xcode-select --install

# 3. Install Homebrew.
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# reopen terminal 

# 4. Generate a fresh SSH key and add it to GitHub.
#    See the [Installation](#installation) section above for the exact commands.

# 5. Clone this repo.
git clone git@github.com:samialdury/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 6. Update Homebrew, then install everything from the Brewfile (formulae + casks + taps).
brew update
brew bundle install --file=Brewfile
brew bundle check  --file=Brewfile   # exits 0 if all installed

# 7. Run the install script (symlinks dotfiles, sets zsh as login shell, applies macOS defaults).
./install.sh

# 8. Open a fresh terminal so the new login shell takes effect, then rehydrate tool versions.
mise install                          # node, ruby from ~/.config/mise/config.toml

# 9. Restore the rest of the secrets that don't live in the repo:
#    ~/.zsh/private.zsh   ~/.aws/   ~/.config/gcloud/   ~/.kube/config   ~/.npmrc   ~/.config/gh/hosts.yml
#    Plus any password-manager / cloud CLI sessions: `gh auth login`, `gcloud auth login`,
#    `stripe login`, `hcloud context create ...`, `turso auth login`, etc.
```

### Install script

```sh
./install.sh
```

On macOS the installer installs Homebrew zsh 5.x plus `zsh-autosuggestions` /
`zsh-syntax-highlighting`, adds `/opt/homebrew/bin/zsh` to `/etc/shells`, and
runs `chsh -s /opt/homebrew/bin/zsh` (will prompt for the sudo and login
passwords). Open a new terminal after install for the shell change to take
effect. The script also keeps Homebrew bash installed because `install.sh`
itself re-execs under Bash 5 (needs Bash 4+ for associative arrays).

### Hyprland

```conf
# Control your input devices
# See https://wiki.hypr.land/Configuring/Variables/#input
input {
  # Use multiple keyboard layouts and switch between them with Left Alt + Right Alt
  kb_layout = cz # us,dk,eu
  kb_variant = qwerty
  kb_options = caps:escape # ,compose:caps,grp:alts_toggle

  # Change speed of keyboard repeat
  repeat_rate = 40
  repeat_delay = 300

  # Start with numlock on by default
  numlock_by_default = true

  # Increase sensitivity for mouse/trackpad (default: 0)
  # sensitivity = 0.35

  touchpad {
    # Use natural (inverse) scrolling
    natural_scroll = true

    # Use two-finger clicks for right-click instead of lower-right corner
    clickfinger_behavior = true

    # Control the speed of your scrolling
    scroll_factor = 0.4
  }
}

# Scroll nicely in the terminal
windowrule = scrolltouchpad 1.5, class:(Alacritty|kitty)
windowrule = scrolltouchpad 0.2, class:com.mitchellh.ghostty

# Enable touchpad gestures for changing workspaces
# See https://wiki.hyprland.org/Configuring/Gestures/
# gesture = 3, horizontal, workspace
```

## Troubleshooting

### SSH

If you encounter issues with GitHub SSH authentication, try adding this to your `.ssh/config`:

```ssh-config
Host github.com
    User git
    HostName github.com
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/id_ed25519
```

## Other

### Brew bundle

```sh
# Snapshot current Homebrew state into Brewfile (formulae, casks, taps, mas/vscode if present).
brew bundle dump --describe --force --file=~/dotfiles/Brewfile

# Install everything listed. Re-runs are safe — already-installed items are skipped.
brew bundle install --file=~/dotfiles/Brewfile

# Useful extras:
brew bundle check   --file=~/dotfiles/Brewfile         # exit 0 iff nothing missing
brew bundle list    --file=~/dotfiles/Brewfile         # show entries
brew bundle cleanup --file=~/dotfiles/Brewfile         # dry-run: items installed but not in file
brew bundle cleanup --file=~/dotfiles/Brewfile --force # actually uninstall the diff
```

### Gitleaks

```sh
gitleaks detect
gitleaks protect --staged
```

## License

[MIT](LICENSE)
