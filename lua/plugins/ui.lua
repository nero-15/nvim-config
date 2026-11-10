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
          -- 並走中の Claude: 判断待ち / 完了・未読 / 作業中 の数 (R-14)。<leader>aw で跳ぶ
          {
            function()
              return require("workflow.agents").statusline()
            end,
            cond = function()
              local agents = package.loaded["workflow.agents"]
              return agents ~= nil and next(agents.sessions) ~= nil
            end,
            color = function()
              local state = require("workflow.agents").top_state()
              local colors = { waiting = "#ff9e64", done = "#9ece6a", working = "#7aa2f7" }
              return { fg = colors[state] or "#565f89", gui = state == "waiting" and "bold" or "" }
            end,
          },
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
