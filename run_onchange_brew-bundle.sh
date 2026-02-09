#!/bin/zsh

# A script that's executed only when the content is changed
# This is executed after chezmoi renders latest ~/.config/brew/Brewfile.

if command -v brew >/dev/null 2>&1; then
  echo "[chezmoi] Running brew bundle based on ~/.config/brew/Brewfile"
  brew bundle --file="$HOME/.config/brew/Brewfile"
else
  echo "[chezmoi] brew not found, skipping brew bundle" >&2
fi

