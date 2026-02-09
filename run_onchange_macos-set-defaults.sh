#!/bin/zsh
# Dock Configuration #
# Enable 'Automatically hide and show the Dock'
defaults write com.apple.dock autohide -bool true; killall Dock

# Mission Control #
# Disable 'Automatically rearrange Spaces based on most recent use'
defaults write com.apple.dock mru-spaces -bool false; killall Dock

# Languages & Region #
# Set 'Preferred Languages'
defaults write -g AppleLanguages -array "en" "ko"
