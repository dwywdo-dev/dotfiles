local bujo_ctx = {
  monthly_year = nil,
  monthly_month = nil,
  yearly_year = nil,
  yearly_quarter = nil,
}

local month_abbr = {
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec",
}

local function build_month_sections(year, month)
  local last_day = tonumber(os.date("%d", os.time({ year = year, month = month + 1, day = 0 })))
  local mm = month_abbr[month] or "Mon"
  local lines = {}
  for d = 1, last_day do
    lines[#lines + 1] = ("## %s-%02d"):format(mm, d)
  end
  return table.concat(lines, "\n")
end

local function build_quarter_sections(year, quarter)
  local start_month = ((quarter - 1) * 3) + 1
  local lines = {}
  for i = 0, 2 do
    lines[#lines + 1] = ("## %04d-%02d"):format(year, start_month + i)
  end
  return table.concat(lines, "\n")
end

return {
  "epwalsh/obsidian.nvim",
  version = "*",
  cmd = {
    "ObsidianNewFromTemplate",
    "ObsidianTemplate",
    "BujoLog",
    "BujoLogPrev",
    "BujoLogNext",
  },
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    disable_frontmatter = false,
    note_frontmatter_func = function(note)
      local out = {}

      if note.tags ~= nil and #note.tags > 0 then
        out.tags = note.tags
      end

      if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
        for k, v in pairs(note.metadata) do
          if k ~= "id" and k ~= "aliases" and k ~= "tags" then
            out[k] = v
          end
        end
      end

      return out
    end,
    completion = { nvim_cmp = false },
    mappings = {},
    workspaces = {
      {
        name = "dwywdo-dev",
        path = "~/dwywdo-dev/repositories/dwywdo_vault",
      },
      {
        name = "lp12495",
        path = "~/lp12495/repositories/lp12495_vault",
      },

    },
    ui = { enable = false },
    templates = {
      folder = "900_Bujo/Templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
      substitutions = {
        month_sections = function()
          if bujo_ctx.monthly_year == nil or bujo_ctx.monthly_month == nil then
            return ""
          end
          return build_month_sections(bujo_ctx.monthly_year, bujo_ctx.monthly_month)
        end,
        quarter_sections = function()
          if bujo_ctx.yearly_year == nil or bujo_ctx.yearly_quarter == nil then
            return ""
          end
          return build_quarter_sections(bujo_ctx.yearly_year, bujo_ctx.yearly_quarter)
        end,
      },
    },
  },
  config = function(_, opts)
    require("obsidian").setup(opts)

    local obsidian = require("obsidian")

    local function exists(path)
      return vim.uv.fs_stat(path) ~= nil
    end

    local function with_ctx(ctx, fn)
      if not ctx then
        return fn()
      end

      local prev = {}
      for k, v in pairs(ctx) do
        prev[k] = bujo_ctx[k]
        bujo_ctx[k] = v
      end

      local ok, r1, r2 = pcall(fn)

      for k, _ in pairs(ctx) do
        bujo_ctx[k] = prev[k]
      end

      if not ok then
        error(r1)
      end

      return r1, r2
    end

    local function create_if_missing(rel_path, template, open_after_create, open_if_exists, ctx)
      local client = obsidian.get_client()
      local vault_root = tostring(client:vault_root())
      local abs_path = vim.fs.joinpath(vault_root, rel_path)

      if exists(abs_path) then
        if open_if_exists then
          vim.cmd("edit " .. vim.fn.fnameescape(abs_path))
          return false, nil
        end
        vim.notify("Skip (already exists): " .. rel_path, vim.log.levels.INFO)
        return false, nil
      end

      local note = with_ctx(ctx, function()
        local dir = vim.fs.dirname(rel_path)
        local id = vim.fs.basename(rel_path):gsub("%.md$", "")
        return client:create_note({
          id = id,
          dir = dir,
          template = template,
        })
      end)

      if open_after_create ~= false then
        client:open_note(note, { sync = true })
      end

      return true, note
    end

    local function shift_date(date_str, delta_days)
      local y = tonumber(date_str:sub(1, 4))
      local m = tonumber(date_str:sub(6, 7))
      local d = tonumber(date_str:sub(9, 10))
      local ts = os.time({ year = y, month = m, day = d + delta_days })
      return os.date("%Y-%m-%d", ts)
    end

    local function shift_month(month_str, delta_months)
      local y = tonumber(month_str:sub(1, 4))
      local m = tonumber(month_str:sub(6, 7)) + delta_months

      while m < 1 do
        m = m + 12
        y = y - 1
      end

      while m > 12 do
        m = m - 12
        y = y + 1
      end

      return string.format("%04d-%02d", y, m)
    end

    local function shift_quarter(year, quarter, delta_quarters)
      local idx = year * 4 + (quarter - 1) + delta_quarters
      local new_year = math.floor(idx / 4)
      local new_quarter = (idx % 4) + 1
      return new_year, new_quarter
    end

    local function parse_current_periodic()
      local path = vim.api.nvim_buf_get_name(0)

      local daily = path:match("/000_Periodics/%d%d%d%d/Daily/(%d%d%d%d%-%d%d%-%d%d)%.md$")
      if daily then
        return "daily", daily
      end

      local monthly = path:match("/000_Periodics/%d%d%d%d/Monthly/(%d%d%d%d%-%d%d)%.md$")
      if monthly then
        return "monthly", monthly
      end

      local y, q = path:match("/000_Periodics/(%d%d%d%d)/Yearly/%d%d%d%d%-(%d)Q%.md$")
      if y and q then
        return "quarterly", tonumber(y), tonumber(q)
      end

      return nil
    end

    local function open_adjacent_log(delta)
      local kind, a, b = parse_current_periodic()
      if kind == nil then
        vim.notify("Current file is not a Daily/Monthly/Yearly(Quarter) log.", vim.log.levels.ERROR)
        return
      end

      if kind == "daily" then
        local target = shift_date(a, delta)
        local y = target:sub(1, 4)
        create_if_missing(
          ("000_Periodics/%s/Daily/%s.md"):format(y, target),
          "log-daily.md",
          true,
          true
        )
        return
      end

      if kind == "monthly" then
        local target = shift_month(a, delta)
        local y = target:sub(1, 4)
        local m = tonumber(target:sub(6, 7))
        create_if_missing(
          ("000_Periodics/%s/Monthly/%s.md"):format(y, target),
          "log-monthly.md",
          true,
          true,
          { monthly_year = tonumber(y), monthly_month = m }
        )
        return
      end

      local y, q = shift_quarter(a, b, delta)
      create_if_missing(
        ("000_Periodics/%d/Yearly/%d-%dQ.md"):format(y, y, q),
        "log-yearly.md",
        true,
        true,
        { yearly_year = y, yearly_quarter = q }
      )
    end

    vim.api.nvim_create_user_command("BujoLog", function(data)
      local arg = vim.trim(data.args or "")

      if arg == "" then
        local y = os.date("%Y")
        local d = os.date("%Y-%m-%d")
        create_if_missing(("000_Periodics/%s/Daily/%s.md"):format(y, d), "log-daily.md")
        return
      end

      if arg:match("^%d%d%d%d%-%d%d%-%d%d$") then
        local y = arg:sub(1, 4)
        create_if_missing(("000_Periodics/%s/Daily/%s.md"):format(y, arg), "log-daily.md")
        return
      end

      if arg:match("^%d%d%d%d%-%d%d$") then
        local y = arg:sub(1, 4)
        local m = arg:sub(6, 7)
        create_if_missing(
          ("000_Periodics/%s/Monthly/%s.md"):format(y, arg),
          "log-monthly.md",
          true,
          false,
          { monthly_year = tonumber(y), monthly_month = tonumber(m) }
        )
        return
      end

      if arg:match("^%d%d%d%d$") then
        local first_created = nil
        for q = 1, 4 do
          local created, note = create_if_missing(
            ("000_Periodics/%s/Yearly/%s-%dQ.md"):format(arg, arg, q),
            "log-yearly.md",
            false,
            false,
            { yearly_year = tonumber(arg), yearly_quarter = q }
          )
          if created and first_created == nil then
            first_created = note
          end
        end
        if first_created ~= nil then
          obsidian.get_client():open_note(first_created, { sync = true })
        end
        return
      end

      vim.notify(
        "Invalid BujoLog argument. Use: :BujoLog | :BujoLog YYYY-MM-DD | :BujoLog YYYY-MM | :BujoLog YYYY",
        vim.log.levels.ERROR
      )
    end, { nargs = "?" })

    vim.api.nvim_create_user_command("BujoLogPrev", function()
      open_adjacent_log(-1)
    end, {})

    vim.api.nvim_create_user_command("BujoLogNext", function()
      open_adjacent_log(1)
    end, {})
  end,
}
