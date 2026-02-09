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
# Note: You need to manually set the message at 'Lock Screen > Show message when locked'
# Always ask for password to unlock
defaults write com.apple.screensaver askForPassword -int 1
# Lock screen when idle for 1 minute, and apply it (after ;)
defaults write com.apple.screensaver loginwindowIdle -int 1

# Keyboard #
# Disable 'Correct spelling automatically'
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
# Disable 'Capatalize words automatically'
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
# Disable 'Add period with double-space'
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false
# Disable 'Use smart quotes and dashed' for Apple apps
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
# Disable 'Use smart quotes and dashed' for System Settings
defaults write NSGlobalDomain NSSmartQuotesAndDashesEnabled -bool false
# Enable Keyboard navigation (Use keyboard navigation to move focus between conrtols)
defaults write NSGlobalDomain NSKeyboardNavigationEnabled -bool true
# Disable 'Press and Hold' (Not visible on System Settings)
defaults write -g ApplePressAndHoldEnabled -bool false

# Function Keys #
# Switch behavior of Function Keys to F1/F2/... as default
defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true

