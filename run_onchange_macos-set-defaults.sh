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

# Lock Screen #
# Always ask for password to unlock
defaults write com.apple.screensaver askForPassword -int 1
# Lock screen when idle for 1 minute, and apply it (after ;)
defaults write com.apple.screensaver loginwindowIdle -int 1;
/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend

