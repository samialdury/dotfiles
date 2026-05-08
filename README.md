# dotfiles

This repository contains all my important dev environment configuration files.
It supports **MacOS** and **Arch Linux**.

<!--toc:start-->
- [Installation](#installation)
- [Usage](#usage)
  - [MacOS prerequisites](#macos-prerequisites)
  - [Install script](#install-script)
- [Troubleshooting](#troubleshooting)
  - [SSH](#ssh)
- [Other](#other)
  - [Brew bundle](#brew-bundle)
  - [Gitleaks](#gitleaks)
- [License](#license)
<!--toc:end-->

## Installation

First, make sure you've created a new ssh key and added it to your GitHub account.

```sh
ssh-keygen -t ed25519 -C "$(hostname)"

# copy pub key to clipboard (macOS or Wayland)
cat ~/.ssh/id_ed25519.pub | $(command -v wl-copy || command -v pbcopy)

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# test connection
ssh -T git@github.com
```

```sh
git clone git@github.com:samialdury/dotfiles.git ~/dotfiles
```

## Usage

### MacOS prerequisites

```sh
# Install Xcode command line tools
xcode-select --install
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Install script

```sh
./install.sh
```

The installer installs Homebrew bash 5.x, adds it to `/etc/shells`, and runs
`chsh -s /opt/homebrew/bin/bash` (will prompt for the sudo and login passwords).
Open a new terminal after install for the shell change to take effect.

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
brew bundle dump --force --file=~/dotfiles/Brewfile
brew bundle install --file=~/dotfiles/Brewfile
```

### Gitleaks

```sh
gitleaks detect
gitleaks protect --staged
```

## License

[MIT](LICENSE)
