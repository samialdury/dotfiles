# macOS-specific zsh config.

alias cwd='echo "$(pwd)" | pbcopy && echo "Copied to clipboard"'
alias lastCommitMsg="git log -1 --pretty=%B | pbcopy && echo 'Copied to clipboard'"
alias lastCommitHash="git log -1 --pretty=%H | pbcopy && echo 'Copied to clipboard'"

alias b="brew update; brew upgrade; brew cleanup; brew cleanup -s; brew doctor; brew missing"
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"

# Plugins: autosuggestions first, syntax-highlighting LAST (per plugin docs)
if [ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  # Dimmer suggestion text; clear suggestion on Alt+Backspace instead of re-suggesting
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=fg=240
  ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(backward-kill-word)
fi

if [ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
