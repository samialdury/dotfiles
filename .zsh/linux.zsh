# Linux-specific zsh config.

# Plugins: autosuggestions first, syntax-highlighting LAST (per plugin docs)
if [ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=fg=240
  ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(backward-kill-word)
fi

if [ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
