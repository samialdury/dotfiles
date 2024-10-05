function fish_greeting
    # fortune | cowsay | lolcat
end

set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx BAT_CONFIG_PATH "$XDG_CONFIG_HOME/bat/bat.conf"
set -gx STARSHIP_CONFIG "$XDG_CONFIG_HOME/starship/starship.toml"

set -gx VISUAL "nvim"
set -gx EDITOR $VISUAL
set -gx GIT_EDITOR $VISUAL

set -gx BIN "/usr/bin:/usr/local/bin"
set -gx HOMEBREW_BIN /opt/homebrew/bin
set -gx PNPM_HOME "$HOME/Library/pnpm"
set -gx CARGO_BIN "$HOME/.cargo/bin"
set -gx BUN_INSTALL "$HOME/.bun"
set -gx GOPATH "$HOME/go"
set -gx LOCAL_BIN "$HOME/.local/bin"
set -gx HERD_BIN "$HOME/Library/Application\ Support/Herd/bin/"

set -gx PATH "$HOMEBREW_BIN:$PATH:$LOCAL_BIN:$BIN:$HERD_BIN:$PNPM_HOME:$CARGO_BIN:$BUN_INSTALL/bin:$GOPATH/bin:$(gem environment gemdir)/bin:$(brew --prefix ruby)/bin"

# Aliases
# fzf
alias search="fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}' | xargs nvim"

# Node.js
alias n="node"
alias p="pnpm"

# Neovim
alias e="nvim"

# Update & clean Homebrew
alias b="brew update; brew upgrade; brew cleanup; brew cleanup -s; brew doctor; brew missing"
# Git
alias g="git"
alias ga="git add"
alias gaa="git add --all"
alias gs="git status"
alias gaa="git add ."
alias gcm="git commit -m"
alias gcmnv="git commit --no-verify -m"
alias gcmnva="git commit --no-verify --amend"
alias gca="git commit --amend"
alias gp="git pull"
alias gpush="git push -u origin HEAD"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gfa="git fetch --all"
alias gpfa="git pull; git fetch --all"
alias gupa="git pull --rebase --autostash"
alias gupav="git pull --rebase --autostash --verbose"
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

# Go
alias gmt="go mod tidy"

# PHP
alias a="php artisan"

# k8s hetzner
# https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner
alias createkh='set tmp_script (mktemp); curl -sSL -o "{tmp_script}" https://raw.githubusercontent.com/kube-hetzner/terraform-hcloud-kube-hetzner/master/scripts/create.sh; chmod +x "{tmp_script}"; bash "{tmp_script}"; rm "{tmp_script}"'
alias cleanupkh='set tmp_script (mktemp) && curl -sSL -o "{tmp_script}" https://raw.githubusercontent.com/kube-hetzner/terraform-hcloud-kube-hetzner/master/scripts/cleanup.sh && chmod +x "{tmp_script}" && bash "{tmp_script}" && rm "{tmp_script}"'

# pnpm
set -gx PNPM_HOME "/Users/sami/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

# shell
set -gx SHELL (command -s fish)

# yazi
function yy
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	yazi $argv --cwd-file="$tmp"
	if set cwd (cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
		cd -- "$cwd"
	end
	rm -f -- "$tmp"
end

# zoxide
zoxide init fish | source

# fnm
fnm env --use-on-cd | source
fnm completions --shell fish | source

# starship prompt
starship init fish | source
