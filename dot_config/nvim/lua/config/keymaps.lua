-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local M = {}

-------------------------------------------------------------------------------
--       Toggle Checkbox and Move to #### Completed tasks at the bottom 
-------------------------------------------------------------------------------

-- Dummy keymapping for testing
-- vim.keymap.set({ "n", "i" }, "<M-x>", function() print("works!") end)

-- HACK: Manage Markdown tasks in Neovim similar to Obsidian | Telescope to List Completed and Pending Tasks
-- https://youtu.be/59hvZl077hM
--
-- If there is no `untoggled` or `done` label on an item, mark it as done
-- and move it to the "#### Completed tasks" markdown heading in the same file, if
-- the heading does not exist, it will be created, if it exists, items will be
-- appended to it at the top lamw25wmal
--
-- If an item is moved to that heading, it will be added the `done` label
vim.keymap.set("n", "<M-x>", function()
  -- Customizable variables
  -- NOTE: Customize the completion label
  local label_done = "done:"
  -- NOTE: Customize the timestamp format
  local timestamp = os.date("%y%m%d-%H%M")
  -- local timestamp = os.date("%y%m%d")
  -- NOTE: Customize the heading and its level
  local tasks_heading = "#### Completed Tasks"
  -- Save the view to preserve folds
  vim.cmd("mkview")
  local api = vim.api
  -- Retrieve buffer & lines
  local buf = api.nvim_get_current_buf()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local start_line = cursor_pos[1] - 1
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local total_lines = #lines
  -- If cursor is beyond last line, do nothing
  if start_line >= total_lines then
    vim.cmd("loadview")
    return
  end
  ------------------------------------------------------------------------------
  -- (A) Move upwards to find the bullet line (if user is somewhere in the chunk)
  ------------------------------------------------------------------------------
  while start_line > 0 do
    local line_text = lines[start_line + 1]
    -- Stop if we find a blank line or a bullet line
    if line_text == "" or line_text:match("^%s*%-") then
      break
    end
    start_line = start_line - 1
  end
  -- Now we might be on a blank line or a bullet line
  if lines[start_line + 1] == "" and start_line < (total_lines - 1) then
    start_line = start_line + 1
  end
  ------------------------------------------------------------------------------
  -- (B) Validate that it's actually a task bullet, i.e. '- [ ]' or '- [x]'
  ------------------------------------------------------------------------------
  local bullet_line = lines[start_line + 1]
  if not bullet_line:match("^%s*%- %[[x ]%]") then
    -- Not a task bullet => show a message and return
    print("Not a task bullet: no action taken.")
    vim.cmd("loadview")
    return
  end
  ------------------------------------------------------------------------------
  -- 1. Identify the chunk boundaries
  ------------------------------------------------------------------------------
  local chunk_start = start_line
  local chunk_end = start_line
  while chunk_end + 1 < total_lines do
    local next_line = lines[chunk_end + 2]
    if next_line == "" or next_line:match("^%s*%-") then
      break
    end
    chunk_end = chunk_end + 1
  end
  -- Collect the chunk lines
  local chunk = {}
  for i = chunk_start, chunk_end do
    table.insert(chunk, lines[i + 1])
  end
  ------------------------------------------------------------------------------
  -- 2. Check if chunk has [done: ...] or [untoggled], then transform them
  ------------------------------------------------------------------------------
  local has_done_index = nil
  local has_untoggled_index = nil
  for i, line in ipairs(chunk) do
    -- Replace `[done: ...]` -> `` `done: ...` ``
    chunk[i] = line:gsub("%[done:([^%]]+)%]", "`" .. label_done .. "%1`")
    -- Replace `[untoggled]` -> `` `untoggled` ``
    chunk[i] = chunk[i]:gsub("%[untoggled%]", "`untoggled`")
    if chunk[i]:match("`" .. label_done .. ".-`") then
      has_done_index = i
      break
    end
  end
  if not has_done_index then
    for i, line in ipairs(chunk) do
      if line:match("`untoggled`") then
        has_untoggled_index = i
        break
      end
    end
  end
  ------------------------------------------------------------------------------
  -- 3. Helpers to toggle bullet
  ------------------------------------------------------------------------------
  -- Convert '- [ ]' to '- [x]'
  local function bulletToX(line)
    return line:gsub("^(%s*%- )%[%s*%]", "%1[x]")
  end
  -- Convert '- [x]' to '- [ ]'
  local function bulletToBlank(line)
    return line:gsub("^(%s*%- )%[x%]", "%1[ ]")
  end
  ------------------------------------------------------------------------------
  -- 4. Insert or remove label *after* the bracket
  ------------------------------------------------------------------------------
  local function insertLabelAfterBracket(line, label)
    local prefix = line:match("^(%s*%- %[[x ]%])")
    if not prefix then
      return line
    end
    local rest = line:sub(#prefix + 1)
    return prefix .. " " .. label .. rest
  end
  local function removeLabel(line)
    -- If there's a label (like `` `done: ...` `` or `` `untoggled` ``) right after
    -- '- [x]' or '- [ ]', remove it
    return line:gsub("^(%s*%- %[[x ]%])%s+`.-`", "%1")
  end
  ------------------------------------------------------------------------------
  -- 5. Update the buffer with new chunk lines (in place)
  ------------------------------------------------------------------------------
  local function updateBufferWithChunk(new_chunk)
    for idx = chunk_start, chunk_end do
      lines[idx + 1] = new_chunk[idx - chunk_start + 1]
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end
  ------------------------------------------------------------------------------
  -- 6. Main toggle logic
  ------------------------------------------------------------------------------
  if has_done_index then
    chunk[has_done_index] = removeLabel(chunk[has_done_index]):gsub("`" .. label_done .. ".-`", "`untoggled`")
    chunk[1] = bulletToBlank(chunk[1])
    chunk[1] = removeLabel(chunk[1])
    chunk[1] = insertLabelAfterBracket(chunk[1], "`untoggled`")
    updateBufferWithChunk(chunk)
    vim.notify("Untoggled", vim.log.levels.INFO)
  elseif has_untoggled_index then
    chunk[has_untoggled_index] =
      removeLabel(chunk[has_untoggled_index]):gsub("`untoggled`", "`" .. label_done .. " " .. timestamp .. "`")
    chunk[1] = bulletToX(chunk[1])
    chunk[1] = removeLabel(chunk[1])
    chunk[1] = insertLabelAfterBracket(chunk[1], "`" .. label_done .. " " .. timestamp .. "`")
    updateBufferWithChunk(chunk)
    vim.notify("Completed", vim.log.levels.INFO)
  else
    -- Save original window view before modifications
    local win = api.nvim_get_current_win()
    local view = api.nvim_win_call(win, function()
      return vim.fn.winsaveview()
    end)
    chunk[1] = bulletToX(chunk[1])
    chunk[1] = insertLabelAfterBracket(chunk[1], "`" .. label_done .. " " .. timestamp .. "`")
    -- Remove chunk from the original lines
    for i = chunk_end, chunk_start, -1 do
      table.remove(lines, i + 1)
    end
    -- Append chunk under 'tasks_heading'
    local heading_index = nil
    for i, line in ipairs(lines) do
      if line:match("^" .. tasks_heading) then
        heading_index = i
        break
      end
    end
    if heading_index then
      for _, cLine in ipairs(chunk) do
        table.insert(lines, heading_index + 1, cLine)
        heading_index = heading_index + 1
      end
      -- Remove any blank line right after newly inserted chunk
      local after_last_item = heading_index + 1
      if lines[after_last_item] == "" then
        table.remove(lines, after_last_item)
      end
    else
      table.insert(lines, tasks_heading)
      for _, cLine in ipairs(chunk) do
        table.insert(lines, cLine)
      end
      local after_last_item = #lines + 1
      if lines[after_last_item] == "" then
        table.remove(lines, after_last_item)
      end
    end
    -- Update buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.notify("Completed", vim.log.levels.INFO)
    -- Restore window view to preserve scroll position
    api.nvim_win_call(win, function()
      vim.fn.winrestview(view)
    end)
  end
  -- Write changes and restore view to preserve folds
  -- "Update" saves only if the buffer has been modified since the last save
  vim.cmd("silent update")
  vim.cmd("loadview")
end, { desc = "[P]Toggle task and move it to 'done'" })

-------------------------------------------------------------------------------
--                   Set current task checkbox to be cancelled ([c])
-------------------------------------------------------------------------------

vim.keymap.set({ "n", "i" }, "<M-c>", function()
  local line = vim.api.nvim_get_current_line()
  local prefix, rest = line:match("^(%s*[-*]%s+)%[[^%]]*%](.*)$")

  if not prefix then
    vim.notify("Not a task checkbox line: no action taken.", vim.log.levels.INFO)
    return
  end

  local updated = prefix .. "[c]" .. rest
  if updated == line then
    return
  end

  vim.api.nvim_set_current_line(updated)
end, { desc = "Set task checkbox to be cancelled ([c])" })

-------------------------------------------------------------------------------
--                          Add a checkbox (- [ ])
-------------------------------------------------------------------------------

vim.keymap.set({ "n", "i" }, "<M-l>", function()
  local box_options = {
    { key = " ", box = "[ ]", desc = "Task" },
    { key = "<", box = "[<]", desc = "Scheduled" },
    { key = ">", box = "[>]", desc = "Migrated" },
    { key = "*", box = "[*]", desc = "Starred" },
    { key = "i", box = "[i]", desc = "Idea" },
    { key = "q", box = "[q]", desc = "Questionable" },
    { key = "b", box = "[b]", desc = "Backlog" },
    { key = "g", box = "[g]", desc = "Good" },
    { key = "n", box = "[n]", desc = "No Good" },
  }

  local box_by_key = {}
  for _, opt in ipairs(box_options) do
    box_by_key[opt.key] = opt.box
  end

  local function key_label(key)
    if key == " " then
      return "<Space>"
    end
    return key
  end

  local function get_box()
    local lines = { "M-l options (key : meaning):" }
    for _, opt in ipairs(box_options) do
      lines[#lines + 1] = string.format("%-8s: %s", key_label(opt.key), opt.desc)
    end
    lines[#lines + 1] = "others  : Task"
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Checkbox Type" })

    -- M-l 이후 한 글자를 더 입력받아 체크박스 형태 결정
    local ok, key = pcall(vim.fn.getcharstr)
    if not ok or key == nil or key == "" then
      return "[ ]"
    end

    return box_by_key[key] or "[ ]"
  end

  local box = get_box()
  local prefix = "- " .. box .. " " -- 예: "- [ ] " 또는 "- [i] "

  -- 현재 커서/라인
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row = cursor_pos[1]
  local line = vim.api.nvim_get_current_line()

  -- 1) 빈 줄이면 새 체크박스 항목 생성
  if line:match("^%s*$") then
    vim.api.nvim_set_current_line(prefix)
    vim.api.nvim_win_set_cursor(0, { row, #prefix })
    return
  end

  -- 2) 이미 체크박스가 있으면:
  --    - 같은 타입이면 아무것도 하지 않음
  --    - 다른 타입이면 체크박스만 교체
  local cb_bullet, cb_value, cb_rest = line:match("^([%s]*[-*]%s+)%[([^%]]*)%]%s*(.*)$")
  if cb_bullet then
    local current_box = "[" .. cb_value .. "]"
    if current_box == box then
      return
    end
    local final_line = cb_bullet .. box .. " " .. cb_rest
    vim.api.nvim_set_current_line(final_line)
    vim.api.nvim_win_set_cursor(0, { row, #cb_bullet + #box + 1 })
    return
  end

  -- 3) 기존 bullet(-/*)가 있으면 체크박스로 변환
  local bullet, text = line:match("^([%s]*[-*]%s+)(.*)$")
  if bullet then
    local final_line = bullet .. box .. " " .. text
    vim.api.nvim_set_current_line(final_line)
    vim.api.nvim_win_set_cursor(0, { row, #bullet + #box + 1 })
    return
  end

  -- 4) 일반 텍스트면 앞에 체크박스 bullet 추가
  local final_line = prefix .. line
  vim.api.nvim_set_current_line(final_line)
  vim.api.nvim_win_set_cursor(0, { row, #prefix })
end, { desc = "Insert task bullet (M-l then l/i/...)" })

-------------------------------------------------------------------------------
--                           Folding section
-------------------------------------------------------------------------------

vim.keymap.set("n", "<CR>", function()
  local line_num = vim.fn.line(".")
  local current_line = vim.fn.getline(line_num)
  
  if string.match(current_line, "^#+%s") then
    local foldlevel = vim.fn.foldlevel(line_num)
    if foldlevel == 0 then
      vim.notify("No fold found", vim.log.levels.INFO)
    else
      vim.cmd("normal! za")
      vim.cmd("normal! zz")
    end
  else
    vim.cmd("normal! j")
  end
end, { desc = "[P]Toggle fold or Move to next line" })

-------------------------------------------------------------------------------
--      HACK: Neovim Toggle Terminal on Tmux Pane at the Bottom (or Right)
--                        https://youtu.be/33gQ9p-Zp0I
--
-- Toggle a tmux pane on the right in zsh, in the same directory as the current file
--
-- Notice I'm setting the variable DISABLE_PULL=1, because in my zshrc file,
-- I check if this variable is set, if it is, I don't pull github repos, to save time
--
-- I keep track of the opened dir lamw25wmal, and if it changes, the next time I
-- bring up the tmux pane, it will open the path of the new dir
--
-- I defined it as a function, because I call this function from the
-- mini.files plugin to open the highlighted dir in a tmux pane on the right
-------------------------------------------------------------------------------
M.tmux_pane_function = function(dir)
  -- NOTE: variable that controls the auto-cd behavior
  local auto_cd_to_new_dir = true
  -- NOTE: Variable to control pane direction: 'right' or 'bottom'
  -- If you modify this, make sure to also modify TMUX_PANE_DIRECTION in the
  -- zsh-vi-mode section on the .zshrc file
  -- Also modify this in your tmux.conf file if you want it to work when in tmux
  -- copy-mode
  local pane_direction = vim.g.tmux_pane_direction or "right"
  -- NOTE: Below, the first number is the size of the pane if split horizontally,
  -- the 2nd number is the size of the pane if split vertically
  local pane_size = (pane_direction == "right") and 60 or 15
  local move_key = (pane_direction == "right") and "C-l" or "C-k"
  local split_cmd = (pane_direction == "right") and "-h" or "-v"
  -- if no dir is passed, use the current file's directory
  local file_dir = dir or vim.fn.expand("%:p:h")
  -- Simplified this, was checking if a pane existed
  local has_panes = vim.fn.system("tmux list-panes | wc -l"):gsub("%s+", "") ~= "1"
  -- Check if the current pane is zoomed (maximized)
  local is_zoomed = vim.fn.system("tmux display-message -p '#{window_zoomed_flag}'"):gsub("%s+", "") == "1"
  -- Escape the directory path for shell
  local escaped_dir = file_dir:gsub("'", "'\\''")
  -- If any additional pane exists
  if has_panes then
    if is_zoomed then
      -- Compare the stored pane directory with the current file directory
      if auto_cd_to_new_dir and vim.g.tmux_pane_dir ~= escaped_dir then
        -- If different, cd into the new dir
        vim.fn.system("tmux send-keys -t :.+ 'cd \"" .. escaped_dir .. "\"' Enter")
        -- Update the stored directory to the new one
        vim.g.tmux_pane_dir = escaped_dir
      end
      -- If zoomed, unzoom and switch to the correct pane
      vim.fn.system("tmux resize-pane -Z")
      vim.fn.system("tmux send-keys " .. move_key)
    else
      -- If not zoomed, zoom current pane
      vim.fn.system("tmux resize-pane -Z")
    end
  else
    -- Store the initial directory in a Neovim variable
    if vim.g.tmux_pane_dir == nil then
      vim.g.tmux_pane_dir = escaped_dir
    end
    -- If no pane exists, open it with zsh and DISABLE_PULL variable
    vim.fn.system(
      "tmux split-window "
        .. split_cmd
        .. " -l "
        .. pane_size
        .. " 'cd \""
        .. escaped_dir
        .. "\" && DISABLE_PULL=1 zsh'"
    )
    vim.fn.system("tmux send-keys " .. move_key)
    -- Resolve zsh-vi-mode issue for first-time pane
    vim.fn.system("tmux send-keys Escape i")
  end
end
-- If I execute the function without an argument, it will open the dir where the
-- current file lives
vim.keymap.set({ "n", "v", "i" }, "<M-t>", function()
  M.tmux_pane_function()
end, { desc = "[P]Terminal on tmux pane" })
