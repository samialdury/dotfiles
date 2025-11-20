# dotfiles

This repository contains my dotfiles.

Most of the configuration is in the [.config](.config) directory.

## Installation

```sh
git clone https://github.com/samialdury/dotfiles.git ~/dotfiles
```

## Usage

[USAGE.md](USAGE.md)

## License

[MIT](LICENSE)

# Usage

```sh
# Install xcode command line tools
xcode-select --install

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install fish shell
/opt/homebrew/bin/brew install fish

# Set fish as default shell
echo "/opt/homebrew/bin/fish" | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/fish

# Open a new terminal window

# Install brew packages
brew bundle install --file=~/dotfiles/Brewfile

# Symlink config files
cd ~/dotfiles
make stow

# Set system defaults
make defaults
```

```
Include ~/.orbstack/ssh/config

Host github.com
    User git
    HostName github.com
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/id_ed25519
```
