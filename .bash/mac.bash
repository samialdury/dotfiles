# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# Editor used by CLI
export VISUAL=nvim
export EDITOR="$VISUAL"
export SUDO_EDITOR="$EDITOR"
export GIT_EDITOR="$VISUAL"
export BAT_THEME=ansi

# Color man pages with bat
export MANROFFOPT="-c"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# History control
shopt -s histappend
HISTCONTROL=ignoreboth:erasedups
HISTSIZE=100000
HISTFILESIZE=200000

# Ensure command hashing is off for mise
set +h

# ble.sh — Bash Line Editor (mac only; sourced --noattach, attached at EOF)
if [[ $- == *i* ]] && [ -r "$HOME/.local/share/blesh/ble.sh" ]; then
  source -- "$HOME/.local/share/blesh/ble.sh" --noattach
  bleopt history_share=1

  # Debounce auto-complete: default 1ms (per-keystroke). 300ms = suggestion
  # shows up after typing pauses, not on every key.
  bleopt complete_auto_delay=300

  # Fish-like faces: foreground color only, no bg/underline. `none` must come
  # first — gspec2g iterates L→R and `none` resets g=0, wiping anything before.
  ble-face auto_complete='none,fg=242'      # dim gray suggestion
  ble-face filename_warning='none,fg=red'   # unknown commands / paths
  ble-face command_jobs='none,fg=red'       # fallback for unknown commands
  ble-face syntax_quoted='none,fg=green'    # quoted strings
  ble-face syntax_command='fg=cyan,bold'    # valid commands
  ble-face syntax_error='fg=red,bold'       # syntax errors
fi

# Env
export XDG_CONFIG_HOME="$HOME/.config"

export BIN="/usr/bin:/usr/local/bin"
export HOMEBREW_BIN="/opt/homebrew/bin"
export PNPM_HOME="$HOME/Library/pnpm"
export CARGO_BIN="$HOME/.cargo/bin"
export BUN_INSTALL="$HOME/.bun"
export GOPATH="$HOME/go"
export LOCAL_BIN="$HOME/.local/bin"
export LOCAL_SCRIPTS="$HOME/.local/scripts"

# PATH
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH="$CARGO_BIN:$LOCAL_BIN:$LOCAL_SCRIPTS:$PNPM_HOME:$BUN_INSTALL/bin:$GOPATH/bin:$PATH"

# File system
if command -v eza &>/dev/null; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
fi

alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
alias eff='$EDITOR "$(ff)"'

if command -v zoxide &>/dev/null; then
  alias cd="zd"
  zd() {
    if (($# == 0)); then
      builtin cd ~ || return
    elif [[ -d $1 ]]; then
      builtin cd "$1" || return
    else
      if ! z "$@"; then
        echo "Error: Directory not found"
        return 1
      fi

      printf "\U000F17A9 "
      pwd
    fi
  }
fi

# Directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Tools
alias c='opencode'
alias cx='printf "\033[2J\033[3J\033[H" && claude --permission-mode bypassPermissions'
alias d='docker'
alias r='rails'
n() { if [ "$#" -eq 0 ]; then command nvim .; else command nvim "$@"; fi; }

# Temporary
alias cc='cx'
alias e='n'
alias lg='lazygit'
alias search="fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}' | xargs nvim"
alias cwd='echo "$(pwd)" | pbcopy && echo "Copied to clipboard"'
alias lastCommitMsg="git log -1 --pretty=%B | pbcopy && echo 'Copied to clipboard'"
alias lastCommitHash="git log -1 --pretty=%H | pbcopy && echo 'Copied to clipboard'"
cat() { command bat "$@"; }

# Mac OS
alias b="brew update; brew upgrade; brew cleanup; brew cleanup -s; brew doctor; brew missing"
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"

# Git
alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'

# Keybinds
bind '"\C-f":"tmux-sessionizer\n"'

# Box helpers
[ -r "$HOME/.bash/box.bash" ] && . "$HOME/.bash/box.bash"

# Tool inits
if command -v mise &>/dev/null; then
  eval "$(mise activate bash)"
fi

if [[ $- == *i* ]] && [[ ${TERM:-} != "dumb" ]] && command -v starship &>/dev/null; then
  eval "$(starship init bash)"
fi

if command -v zoxide &>/dev/null; then
  eval "$(zoxide init bash)"
fi

# bash-completion@2 (Homebrew) — must load before fzf-completion regardless of ble.sh
if [ -r /opt/homebrew/etc/profile.d/bash_completion.sh ]; then
  source /opt/homebrew/etc/profile.d/bash_completion.sh
fi

if command -v fzf &>/dev/null; then
  if [[ ${BLE_VERSION-} ]]; then
    _ble_contrib_fzf_base=/opt/homebrew/opt/fzf
    ble-import -d integration/fzf-completion
    ble-import -d integration/fzf-key-bindings
  else
    eval "$(fzf --bash)"
  fi
fi

# Cross-session history sync — ble.sh handles it via bleopt above, otherwise
# wire PROMPT_COMMAND so a fresh shell re-reads other sessions' history.
if [[ -z ${BLE_VERSION-} ]]; then
  PROMPT_COMMAND=('history -a; history -n' "${PROMPT_COMMAND[@]}")
fi

# ble.sh — attach last so it wraps every PROMPT_COMMAND / readline hook
[[ ${BLE_VERSION-} ]] && ble-attach
