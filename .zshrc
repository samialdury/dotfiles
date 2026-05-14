# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# Editor used by CLI
export VISUAL=nvim
export EDITOR="$VISUAL"
export BAT_THEME=ansi

# Color man pages with bat
export MANROFFOPT="-c"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=200000
setopt append_history inc_append_history share_history extended_history
setopt hist_ignore_space hist_ignore_all_dups hist_reduce_blanks
setopt hist_save_no_dups hist_find_no_dups hist_expire_dups_first hist_verify

# Disable command hashing for mise
setopt nohashcmds nohashdirs

# Env
export XDG_CONFIG_HOME="$HOME/.config"

export PNPM_HOME="$HOME/Library/pnpm"
export CARGO_BIN="$HOME/.cargo/bin"
export BUN_INSTALL="$HOME/.bun"
export GOPATH="$HOME/go"
export LOCAL_BIN="$HOME/.local/bin"
export LOCAL_SCRIPTS="$HOME/.local/scripts"

# PATH
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH="$CARGO_BIN:$LOCAL_BIN:$LOCAL_SCRIPTS:$PNPM_HOME:$BUN_INSTALL/bin:$GOPATH/bin:$PATH"

# Completion: case-insensitive, menu-select (.inputrc translation)
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
autoload -Uz compinit && compinit

# History search on arrow keys (.inputrc translation)
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

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
bindkey -s '^F' 'tmux-sessionizer\n'

# Box helpers
[ -r "$HOME/.zsh/box.zsh" ] && . "$HOME/.zsh/box.zsh"

# Tool inits
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

if command -v fzf &>/dev/null; then
  eval "$(fzf --zsh)"
fi

if [[ ${TERM:-} != "dumb" ]] && command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

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

# Private config (gitignored, sourced if present)
[ -r "$HOME/.zsh/private.zsh" ] && . "$HOME/.zsh/private.zsh"
