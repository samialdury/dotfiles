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
