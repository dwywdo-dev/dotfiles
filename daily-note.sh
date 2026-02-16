#!/bin/zsh

# Specify below the directory in which you want to create your daily note
main_note_dir=~/.local/share/dwywdo_vault

# Get current date components
current_year=$(date +"%Y")
current_month_num=$(date +"%m")
current_month_abbr=$(date +"%b")
current_day=$(date +"%d")
current_weekday=$(date +"%A")

# Construct the directory structure and filename
note_dir=${main_note_dir}/${current_year}/${current_month_num}-${current_month_abbr}
note_name=${current_year}-${current_month_num}-${current_day}-${current_weekday}
full_path=${note_dir}/${note_name}.md

# Check if the directory exists, if not, create it
if [ ! -d "$note_dir" ]; then
  mkdir -p "$note_dir"
fi

# Create the daily note if it does not already exist
if [ ! -f "$full_path" ]; then
  cat <<EOF >"$full_path"
# ${note_name}

## Daily Note

EOF
fi

###############################################################################
#                      Daily note with Tmux Sessions
###############################################################################

# Use note name as the session name
tmux_session_name=${note_name}

# Check if a tmux session with the note name already exists
if ! tmux has-session -t="$tmux_session_name" 2>/dev/null; then
  # Create a new tmux session with the note name in detached mode and start
  # neovim with the daily note, cursor at the last line
  # + tells neovim to execute a command after opening and G goes to last line
  tmux new-session -d -s "$tmux_session_name" -c "$main_note_dir" "export MD_HEADING_BG=transparent && nvim +norm\ G $full_path"
  # Create a new tmux session with the note name in detached mode and start neovim with the daily note
  # tmux new-session -d -s "$tmux_session_name" "nvim $full_path"
fi

# Check if neovim is running, if not open it
if ! tmux list-panes -t "$tmux_session_name" -F "#{pane_current_command}" | grep -q "nvim"; then
  tmux send-keys -t "$tmux_session_name" "nvim $full_path" C-m
  tmux send-keys -t "$tmux_session_name" "s"
fi

# Switch to the tmux session with the note name
tmux switch-client -t "$tmux_session_name"

