.DEFAULT_GOAL := help

##@ Misc

.PHONY: help
help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: check
check:
	@gitleaks detect
	@gitleaks protect --staged

##@ Back up

.PHONY: backup
backup: ## Back up Brewfile
	brew bundle dump --force --file=$(PWD)/Brewfile
	git add Brewfile
	git commit -m "chore(brew): update Brewfile"
	git push origin main

##@ Settings

.PHONY: defaults
defaults: ## Set up system settings
# https://macos-defaults.com

# Disable font smoothing
	defaults -currentHost write -g AppleFontSmoothing -int 0
# Set screenshots location
	defaults write com.apple.screencapture location -string "~/Desktop/screenshots"
# Automatically empty bin after 30 days
	defaults write com.apple.finder "FXRemoveOldTrashItems" -bool true
# Show hidden files in Finder
	defaults write com.apple.finder AppleShowAllFiles -bool true
# Show all filename extensions in Finder
	defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Show path bar in Finder
	defaults write com.apple.finder ShowPathbar -bool true
# List view by default in Finder
	defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
# Show the app switcher on all displays
	defaults write com.apple.dock appswitcher-all-displays -bool true
# Disable press-and-hold for keys in favor of key repeat
	defaults write -g ApplePressAndHoldEnabled -bool false
# Set click weight to light
	defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 0
# Do not automatically rearrange Spaces based on most recent use
	defaults write com.apple.dock mru-spaces -bool false
# Group windows by application in Mission Control
	defaults write com.apple.dock expose-group-by-app -bool true
# Set Dock to auto-hide
	defaults write com.apple.dock autohide -bool true
# Put Dock on the left
	defaults write com.apple.dock orientation -string "left"
# Do not show recent applications in Dock
	defaults write com.apple.dock show-recents -bool false
# Show only active apps in Dock
	defaults write com.apple.dock static-only -bool true
# Set the icon size of Dock items to 36 pixels
	defaults write com.apple.dock tilesize -int 36

	killall Finder
	killall Dock
	killall SystemUIServer

##@ Stow

.PHONY: stow
stow: ## Stow dotfiles
	@echo "Stowing files..."
	stow .
	@echo ✅
	@echo "Symlinking Cursor files..."
	ln -sf ~/.config/cursor/keybindings.json ~/Library/Application\ Support/Cursor/User/ || true
	ln -sf ~/.config/cursor/settings.json ~/Library/Application\ Support/Cursor/User/ || true
	@echo ✅
	@echo "Symlinking VSCode files..."
	ln -sf ~/.config/vscode/keybindings.json ~/Library/Application\ Support/Code/User/ || true
	ln -sf ~/.config/vscode/settings.json ~/Library/Application\ Support/Code/User/ || true
	@echo ✅
	@echo "Symlinking Windsurf files..."
	ln -sf ~/.config/windsurf/settings.json ~/Library/Application\ Support/Windsurf/User/ || true
	ln -sf ~/.config/windsurf/keybindings.json ~/Library/Application\ Support/Windsurf/User/ || true
	@echo ✅
	@echo "All done!"

.PHONY: unstow
unstow: ## Unstow dotfiles
	@echo "Removing stow links..."
	stow -D .
	@echo ✅
	@echo "Removing Cursor files..."
	rm ~/Library/Application\ Support/Cursor/User/keybindings.json
	rm ~/Library/Application\ Support/Cursor/User/settings.json
	@echo ✅
	@echo "All done!"
