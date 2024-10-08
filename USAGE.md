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

# Install alacritty theme
mkdir -p ~/.config/alacritty/themes
curl -LO --output-dir ~/.config/alacritty/themes https://github.com/catppuccin/alacritty/raw/main/catppuccin-mocha.toml

# Install bat theme
mkdir -p ~/.config/bat/themes
curl -LO --output-dir ~/.config/bat/themes https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme
bat cache --build

# Install delta theme
mkdir -p ~/.config/delta/themes
curl -LO --output-dir ~/.config/delta/themes https://raw.githubusercontent.com/catppuccin/delta/main/catppuccin.gitconfig

# Symlink config files
cd ~/dotfiles
make stow

# Set system defaults
make defaults
```
