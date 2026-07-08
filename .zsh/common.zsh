# Shared interactive zsh config for macOS and Linux.

# Editor used by CLI
export VISUAL=nvim
export EDITOR="$VISUAL"
export BAT_THEME=ansi

# Color man pages with bat
export MANROFFOPT="-c"
if command -v bat >/dev/null 2>&1; then
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

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
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export CARGO_BIN="${CARGO_BIN:-$HOME/.cargo/bin}"
export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
export GOPATH="${GOPATH:-$HOME/go}"
export LOCAL_BIN="${LOCAL_BIN:-$HOME/.local/bin}"
export LOCAL_SCRIPTS="${LOCAL_SCRIPTS:-$HOME/.local/scripts}"

# PATH
case "$(uname -s)" in
Darwin)
  export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"
  export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv zsh)"
  fi
  ;;
*)
  export PNPM_HOME="${PNPM_HOME:-$XDG_DATA_HOME/pnpm}"
  ;;
esac
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
if command -v eza >/dev/null 2>&1; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
fi

if command -v bat >/dev/null 2>&1; then
  alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
  alias search="fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}' | xargs nvim"
  cat() { command bat "$@"; }
else
  alias ff='fzf'
  alias search='fzf | xargs nvim'
fi
alias eff='$EDITOR "$(ff)"'

if command -v zoxide >/dev/null 2>&1; then
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
alias cc='printf "\033[2J\033[3J\033[H" && claude --permission-mode bypassPermissions'
alias cx='printf "\033[2J\033[3J\033[H" && codex --dangerously-bypass-approvals-and-sandbox'
alias d='docker'
alias r='rails'
n() { if [ "$#" -eq 0 ]; then command nvim .; else command nvim "$@"; fi; }

# Temporary
alias lg='lazygit'

# Git
alias g='git'

# Keybinds
bindkey -s '^F' 'tmux-sessionizer\n'

# Alt/Option+Backspace
bindkey '^[^?' backward-kill-word
bindkey '^[^H' backward-kill-word
bindkey '^[b' backward-word
bindkey '^[f' forward-word

# Box helpers
[ -r "$HOME/.zsh/box.zsh" ] && . "$HOME/.zsh/box.zsh"

# Tool inits
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi

if [[ ${TERM:-} != "dumb" ]] && command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
