#!/bin/zsh
boldGreen="\033[1;32m"
boldYellow="\033[1;33m"
boldRed="\033[1;31m"
boldPurple="\033[1;35m"
boldBlue="\033[1;34m"
noColor="\033[0m"

echo
echo "########################################################################"
echo "#                       Configuring macOS...                           #"
echo "########################################################################"
echo "#"

echo "# 1. Dock" 
## Enable 'Automatically hide and show the Dock'
defaults write com.apple.dock autohide -bool true

echo "# 2. Mission Control"
# Disable 'Automatically rearrange Spaces based on most recent use'
defaults write com.apple.dock mru-spaces -bool false
# Enable 'Group windows by application' to work with aerospace in a great manner
defaults write com.apple.dock "expose-group-apps' -bool true; killall Dock 

echo "# 3. Languages & Region"
# Set 'Preferred Languages'
defaults write -g AppleLanguages -array "en" "ko"

echo "# 4. Lock Screen"
echo "⚠️ You need to manually set the message at 'Lock Screen > Show message when locked'"
# Always ask for password to unlock
defaults write com.apple.screensaver askForPassword -int 1
# Lock screen when idle for 1 minute, and apply it (after ;)
defaults write com.apple.screensaver loginwindowIdle -int 1

echo "# 5. Keyboard"
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

echo "# 6. Function Keys"
# Switch behavior of Function Keys to F1/F2/... as default
defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true

echo "# 7. Trackpad"
# Enable 'Tap to click'
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
# Configure 'Use trackpad for dragging - Dragging style' as 'Three finger drag'
defaults write com.apple.AppleMultitouchTrackpad Dragging -int 1

echo "# 8. Keyboard shortcut"
echo "⚠️ You need to uncheck 'Keyboard shortcut > Services > Text > 터미널에서 man 페이지 인덱스 검색'"

# Finder Settings
# General > New Finder window show: Set as HOME
defaults write com.apple.finder NewWindowTarget -string "PfHm" # "Pf"inder + "Hm"ome
# Advanced > Show all filename extensions
defaults write com.apple.finder AppleShowAllExtensions -bool true
# View > Show Path Bar, Show Status Bar
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
# Search in a current folder
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf" # "SC"ope + "cf"urrent + "F"older
defaults write com.apple.finder FXPreferredGroupBy -string "Date Added"
defaults write com.apple.finder FXDefaultSortOrder -string "Name"; killall Finder

echo
echo "########################################################################"
echo "#                       Installing Homebrew...                         #"
echo "########################################################################"
echo "#"

if ! xcode-select -p &>/dev/null; then
  # In the [brew documentation](https://docs.brew.sh/Installation)
  # you can see the macOS Requirements
  echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
  echo "Installing xcode-select, this will take some time, please wait"
  echo -e "${boldYellow}A popup will show up, make sure you accept it${noColor}"
  xcode-select --install

  # Wait for xcode-select to be installed
  echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
  echo "Waiting for xcode-select installation to complete..."
  while ! xcode-select -p &>/dev/null; do
    sleep 20
  done
  echo -e "# ${boldGreen}xcode-select Installed! Proceeding with Homebrew installation.${noColor}"
else
  echo -e "# ${boldGreen}xcode-select is already installed! Proceeding with Homebrew installation.${noColor}"
fi

# Source this in case brew was installed but script needs to re-run
if [ -f ~/.zprofile ]; then
  source ~/.zprofile
fi

# Then go to the main page `https://brew.sh` to find the installation command
if ! command -v brew &>/dev/null; then
  echo
  echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
  echo "Installing brew"
  echo "Enter your password below (if required)"
  # Only install brew if not installed yet
  echo
  echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
  # Install Homebrew
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo "#"
  echo -e "# ${boldGreen}Homebrew installed successfully.${noColor}"
else
  echo "#"
  echo -e "# ${boldGreen}Homebrew is already installed.${noColor}"
fi

# After brew is installed, notice that you need to configure your shell for
# homebrew, you can see this in your terminal output in the **Next steps** section
echo "#"
echo "# Modifying .zprofile file"
CHECK_LINE='eval "$(/opt/homebrew/bin/brew shellenv)"'

# File to be checked and modified
FILE="$HOME/.zprofile"

# Check if the specific line exists in the file
if grep -Fq "$CHECK_LINE" "$FILE"; then
  echo "# Content already exists in $FILE"
else
  # Append the content if it does not exist
  echo -e '\n# Configure shell for brew\n'"$CHECK_LINE" >>"$FILE"
  echo "# Content added to $FILE"
fi

# After adding it to the .zprofile file, make sure to run the command
source $FILE
