# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

[ -r "$HOME/.zsh/common.zsh" ] && . "$HOME/.zsh/common.zsh"

case "$(uname -s)" in
Darwin)
  [ -r "$HOME/.zsh/macos.zsh" ] && . "$HOME/.zsh/macos.zsh"
  ;;
Linux)
  [ -r "$HOME/.zsh/linux.zsh" ] && . "$HOME/.zsh/linux.zsh"
  ;;
esac

# Private config (gitignored, sourced if present)
[ -r "$HOME/.zsh/private.zsh" ] && . "$HOME/.zsh/private.zsh"
