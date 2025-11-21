# dotfiles

This repository contains all my important dev environment configuration files.
It supports **MacOS** and **Arch Linux**.

## Installation

First, make sure you've created a new ssh key and added it to your GitHub account.

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
# Install fish shell
/opt/homebrew/bin/brew install fish
# Set fish as default shell
echo "/opt/homebrew/bin/fish" | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/fish
```

### Install script

```sh
./install.sh
```

## Troubleshooting

### SSH

If you encounter issues with GitHub SSH authentication, try adding this to your `.ssh/config`:

```ssh-config
Include ~/.orbstack/ssh/config

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
@gitleaks detect
@gitleaks protect --staged
```

## License

[MIT](LICENSE)
