return {
  -- change some telescope options and a keymap to browse plugin files
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      -- add a keymap to browse plugin files
      -- stylua: ignore
      {
        "<leader>fp",
        function() require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root }) end,
        desc = "Find Plugin File",
      },
      {
        "<leader>td",
        function() require("telescope.builtin").grep_string(require("telescope.themes").get_ivy({
          prompt_title = "Completed (Done) Tasks",
          search = "^\\s*- \\[x\\] `done:",
          search_dirs = { vim.fn.getcwd() },
          use_regex = true,
          initial_mode = "normal",
          layout_config = { preview_width = 0.5 },
          additional_args = function() return { "--no-ignore" } end,
        }))
        end,
        desc = "[P]Search Completed (Done) Tasks",
      }, 
      {
        "<leader>tt",
        function() require("telescope.builtin").grep_string(require("telescope.themes").get_ivy({
          prompt_title = "Incomplete Tasks",
          search = "^\\s*- \\[ \\]",
          search_dirs = { vim.fn.getcwd() },
          use_regex = true,
          initial_mode = "normal",
          layout_config = { preview_width = 0.5 },
          additional_args = function() return { "--no-ignore" } end,
        }))
        end,
        desc = "[P]Search for completed tasks",
      },
      {
        "<leader>ts",
        function() require("telescope.builtin").grep_string(require("telescope.themes").get_ivy({
          prompt_title = "Schedules",
          search = "^\\s*- \\[<\\]",
          search_dirs = { vim.fn.getcwd() },
          use_regex = true,
          initial_mode = "normal",
          layout_config = { preview_width = 0.5 },
          additional_args = function() return { "--no-ignore" } end,
        }))
        end,
        desc = "[P]Search for Schedules",
      },
      {
        "<leader>ti",
        function() require("telescope.builtin").grep_string(require("telescope.themes").get_ivy({
          prompt_title = "Ideas",
          search = "^\\s*- \\[i\\]",
          search_dirs = { vim.fn.getcwd() },
          use_regex = true,
          initial_mode = "normal",
          layout_config = { preview_width = 0.5 },
          additional_args = function() return { "--no-ignore" } end,
        }))
        end,
        desc = "[P]Search for Ideas",
      },
      {
        "<leader>ti",
        function() require("telescope.builtin").grep_string(require("telescope.themes").get_ivy({
          prompt_title = "Ideas",
          search = "^\\s*- \\[i\\]",
          search_dirs = { vim.fn.getcwd() },
          use_regex = true,
          initial_mode = "normal",
          layout_config = { preview_width = 0.5 },
          additional_args = function() return { "--no-ignore" } end,
        }))
        end,
        desc = "[P]Search for Ideas",
      },
      {
        "<leader>tq",
        function() require("telescope.builtin").grep_string(require("telescope.themes").get_ivy({
          prompt_title = "Questions",
          search = "^\\s*- \\[q\\]",
          search_dirs = { vim.fn.getcwd() },
          use_regex = true,
          initial_mode = "normal",
          layout_config = { preview_width = 0.5 },
          additional_args = function() return { "--no-ignore" } end,
        }))
        end,
        desc = "[P]Search for Questions",
      },
      {
        "<leader>tb",
        function() require("telescope.builtin").grep_string(require("telescope.themes").get_ivy({
          prompt_title = "Backlog",
          search = "^\\s*- \\[b\\]",
          search_dirs = { vim.fn.getcwd() },
          use_regex = true,
          initial_mode = "normal",
          layout_config = { preview_width = 0.5 },
          additional_args = function() return { "--no-ignore" } end,
        }))
        end,
        desc = "[P]Search for Backlog Items",
      },

      -- change some options
      opts = {
        defaults = {
          layout_strategy = "horizontal",
          layout_config = { prompt_position = "top" },
          sorting_strategy = "ascending",
          winblend = 0,
        },
      },
    },
  }
}

