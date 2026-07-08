# Installation

Use this guide for new machines or full re-linking. The installer is idempotent, but it performs real package installs, symlink writes, shell changes, and macOS defaults. Do not use it as a dry run.

## 1. Create a machine-local SSH key

Each host gets its own key. Do not copy private keys between machines.

```sh
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "$(hostname)" -f ~/.ssh/id_ed25519

# Copy the public key, then add it at https://github.com/settings/keys
cat ~/.ssh/id_ed25519.pub | $(command -v wl-copy || command -v pbcopy)

# macOS
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# Linux / Omarchy alternative
# ssh-add ~/.ssh/id_ed25519

ssh -T git@github.com
```

## 2. Clone the repo

```sh
git clone git@github.com:samialdury/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

## 3. macOS fresh-machine bootstrap

Start with iCloud/password-manager sign-in, then install Apple's command-line tools and Homebrew.

```sh
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Open a new terminal after Homebrew installation, then install the Brewfile contents before running the dotfiles installer:

```sh
cd ~/dotfiles
brew update
brew bundle install --file=Brewfile
brew bundle check --file=Brewfile
./install.sh
```

What `./install.sh` does on macOS:

- bootstraps/re-execs Homebrew Bash if the current Bash is older than 4.x
- checks the Brewfile and warns if packages are missing
- sets the login shell to `/opt/homebrew/bin/zsh` when available
- links base, AI, shared CLI, zsh, macOS GUI, and Homebrew config
- ensures `~/.zsh/private.zsh` exists
- selects the active AeroSpace config
- applies macOS defaults
- configures this repo's committed Git hooks

After install, open a fresh terminal and rehydrate tool versions:

```sh
mise install
```

Restore secrets and external sessions manually:

```text
~/.zsh/private.zsh
~/.aws/
~/.config/gcloud/
~/.kube/config
~/.npmrc
~/.config/gh/hosts.yml
```

Then log in to CLIs as needed:

```sh
gh auth login
gcloud auth login
stripe login
hcloud context create ...
turso auth login
```

## 4. Omarchy setup

Omarchy keeps its own shell config. This repo does not link zsh/tmux/starship shell config on Omarchy.

Update the system first, then run the installer:

```sh
sudo pacman -Syu
cd ~/dotfiles
./install.sh
```

For non-interactive runs after you have already updated the system:

```sh
DOTFILES_OMARCHY_UPDATED=1 ./install.sh
```

What `./install.sh` does on Omarchy:

- confirms system update was run
- installs missing packages from the Omarchy package map
- links base, AI, and shared CLI config
- configures this repo's committed Git hooks

## 5. Debian setup

Update the system first, then run the installer:

```sh
sudo apt-get update && sudo apt-get upgrade
cd ~/dotfiles
./install.sh
```

For non-interactive runs after you have already updated the system:

```sh
DOTFILES_DEBIAN_UPDATED=1 ./install.sh
```

What `./install.sh` does on Debian:

- confirms system update was run
- installs missing packages from the Debian package map
- installs optional packages such as `git-delta`, `zoxide`, and `starship` when available
- links base, AI, shared CLI, zsh, tmux, starship, and workmux config
- creates `bat` and `fd` wrapper symlinks when Debian exposes them as `batcat` and `fdfind`
- ensures `~/.zsh/private.zsh` exists
- sets the login shell to `/usr/bin/zsh` when available
- configures this repo's committed Git hooks

## 6. Add or re-link a dotfile

1. Put the file in the repo at its `$HOME`-relative path.
2. Add an entry to the right link group in `install/links.sh`.
3. Run the structure harness:

```sh
./scripts/test-install.sh
```

4. Run the real installer when ready:

```sh
./install.sh
```
