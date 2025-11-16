#!/usr/bin/env bash

if ! command -v tmux >/dev/null 2>&1; then
  if [[ -f /etc/arch-release ]]; then
    echo "installing tmux..."
    sudo pacman -S --noconfirm tmux
  else
    echo "tmux already installed, skipping..."
  fi
fi

if ! command -v stow >/dev/null 2>&1; then
  if [[ -f /etc/arch-release ]]; then
    echo "installing stow..."
    sudo pacman -S --noconfirm stow
  else
    echo "stow already installed, skipping..."
  fi
fi

# Tmux TPM
TPM_DIR=~/.tmux/plugins/tpm
if [ ! -d "$TPM_DIR" ]; then
  echo "installing tmux TPM..."
  git clone https://github.com/tmux-plugins/tpm $TPM_DIR
  echo "tmux TPM installed"
else
  echo "tmux TPM exists, skipping..."
fi

# Tmux sessionizer
TS_BIN=~/.local/scripts/tmux-sessionizer
if ! command -v tmux-sessionizer >/dev/null 2>&1; then
  echo "installing tmux-sessionizer..."
  git clone https://github.com/ThePrimeagen/tmux-sessionizer.git /tmp/tmux-sessionizer
  mkdir -p ~/.local/scripts
  mv /tmp/tmux-sessionizer/tmux-sessionizer $TS_BIN
  chmod +x $TS_BIN
  rm -rf /tmp/tmux-sessionizer
  echo "tmux-sessionizer installed, DONT FORGET TO ADD IT TO YOUR PATH."
else
  echo "tmux-sessionizer exists, skipping..."
fi

echo "install script finished"

