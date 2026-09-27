-- ==========================================================
-- UI: テーマ・ステータスライン・アイコン
-- ==========================================================

--- ステータスラインに「今どの worktree にいるか」を出す (R-05)
local function worktree()
  local project = require("workflow.project")
  local cwd = project.cwd()
  local icon = project.agent_name(cwd) and "󰚩 " or " "
  return icon .. project.label(cwd)
end

return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night",
      on_highlights = function(hl, c)
        -- 外部で更新された行・差分を見やすく
        hl.DiffAdd = { bg = "#20303b" }
        hl.DiffDelete = { bg = "#37222c" }
        hl.TabLineSel = { fg = c.bg_dark, bg = c.blue, bold = true }
      end,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  -- アイコン (Nerd Font 前提。Ghostty / Terminal.app ともに Hack Nerd Font)
  {
    "nvim-mini/mini.icons",
    lazy = true,
    opts = {},
    init = function()
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
  },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        theme = "tokyonight",
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        globalstatus = true,
        disabled_filetypes = { statusline = { "snacks_dashboard" } },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { { worktree, color = { gui = "bold" } }, "branch", "diff" },
        lualine_c = { { "filename", path = 1, symbols = { modified = " ●", readonly = " " } } },
        lualine_x = {
          "diagnostics",
          {
            function()
              return " REC @" .. vim.fn.reg_recording()
            end,
            cond = function()
              return vim.fn.reg_recording() ~= ""
            end,
            color = { fg = "#ff9e64" },
          },
          "filetype",
        },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
      extensions = { "quickfix", "lazy", "man", "oil" },
    },
  },
}
