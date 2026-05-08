# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# OS-aware: prefer Omarchy on Arch, fallback to mac.bash
if [ -r "$HOME/.local/share/omarchy/default/bash/rc" ]; then
  # All the default Omarchy aliases and functions
  # (don't mess with these directly, just overwrite them here!)
  . "$HOME/.local/share/omarchy/default/bash/rc"
elif [ -r "$HOME/.bash/mac.bash" ]; then
  . "$HOME/.bash/mac.bash"
fi

# Private config (gitignored, sourced if present)
[ -r "$HOME/.bash/private.bash" ] && . "$HOME/.bash/private.bash"
