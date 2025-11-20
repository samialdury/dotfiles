function fish_greeting
    # fortune | cowsay | lolcat
end

set -gx XDG_CONFIG_HOME "$HOME/.config"

set -gx VISUAL nvim
set -gx EDITOR $VISUAL
set -gx GIT_EDITOR $VISUAL

set -gx BIN "/usr/bin:/usr/local/bin"
set -gx HOMEBREW_BIN /opt/homebrew/bin
set -gx PNPM_HOME "$HOME/Library/pnpm"
set -gx CARGO_BIN "$HOME/.cargo/bin"
set -gx BUN_INSTALL "$HOME/.bun"
set -gx GOPATH "$HOME/go"
set -gx LOCAL_BIN "$HOME/.local/bin"
set -gx LOCAL_SCRIPTS "$HOME/.local/scripts"

set -gx PATH /opt/homebrew/bin /opt/homebrew/sbin /usr/local/bin /usr/bin /bin /usr/sbin /sbin
set -gx PATH $CARGO_BIN $LOCAL_BIN $LOCAL_SCRIPTS $PNPM_HOME $BUN_INSTALL/bin $GOPATH/bin $PATH

# set -gx PATH $CARGO_BIN $HOMEBREW_BIN $LOCAL_BIN $HERD_BIN $PNPM_HOME $BUN_INSTALL/bin $GOPATH/bin /opt/homebrew/opt/libpq/bin /opt/homebrew/opt/ruby/bin $PATH

# if command -v brew >/dev/null 2>&1
#     set -l ruby_prefix (brew --prefix ruby 2>/dev/null)
#     if test -n "$ruby_prefix"
#         set -gx PATH $ruby_prefix/bin $PATH
#     end
# end
#
# if command -v gem >/dev/null 2>&1
#     set -l gem_dir (gem environment gemdir 2>/dev/null)
#     if test -n "$gem_dir"
#         set -gx PATH $gem_dir/bin $PATH
#     end
# end

set private_config ~/.config/fish/private.fish
test -r $private_config; and source $private_config

# Aliases
# fzf
alias search="fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}' | xargs nvim"

alias n="node"
alias p="pnpm"
alias r="ruby"
alias e="nvim"
# Update & clean Homebrew
alias b="brew update; brew upgrade; brew cleanup; brew cleanup -s; brew doctor; brew missing"
# alias git-https="git remote set-url origin https://github.com/$(git remote get-url origin | sed 's/https:\/\/github.com\///' | sed 's/git@github.com://')"
# alias git-ssh=" git remote set-url origin git@github.com:$(git remote get-url origin | sed 's/https:\/\/github.com\///' | sed 's/git@github.com://')"
alias lg="lazygit"
alias ls="eza"
alias ll="eza -lh --icons --git"
alias llt="eza -1 --tree --icons --git-ignore"
alias l="eza -lah"
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias pnpx="pnpm dlx"
alias cwd="echo (pwd) | pbcopy && echo 'Copied to clipboard'"
alias lastCommitMsg="git log -1 --pretty=%B | pbcopy && echo 'Copied to clipboard'"
alias lastCommitHash="git log -1 --pretty=%H | pbcopy && echo 'Copied to clipboard'"
alias cat="bat"
alias cc="ENABLE_BACKGROUND_TASKS=1 claude --dangerously-skip-permissions"

# pnpm
set -gx PNPM_HOME /Users/sami/Library/pnpm
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

# shell
set -gx SHELL (command -s fish)

# keybinds
bind \cf tmux-sessionizer

# Check if commands exist before trying to initialize them
# zoxide
if command -v zoxide >/dev/null 2>&1
    zoxide init fish | source
end

# starship prompt
if command -v starship >/dev/null 2>&1
    starship init fish | source
end

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.fish 2>/dev/null || :

# if status is-interactive
#     if command -v mise >/dev/null 2>&1
mise activate fish | source
#     end
# else
#     if command -v mise >/dev/null 2>&1
mise activate fish --shims | source
#     end
# end
