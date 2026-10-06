-- ==========================================================
-- AI: Claude Code を Neovim の中で扱う (R-09, ADR-0003)
--   メイン: claudecode.nvim (IDE 連携。選択範囲の送信・diff の受理/拒否)
--   追加:   :ClaudeNew / :ClaudeSessions で並走させる (lua/workflow/claude.lua)
-- ==========================================================

return {
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    cmd = {
      "ClaudeCode", "ClaudeCodeFocus", "ClaudeCodeSelectModel", "ClaudeCodeAdd", "ClaudeCodeSend",
      "ClaudeCodeTreeAdd", "ClaudeCodeStatus", "ClaudeCodeStart", "ClaudeCodeStop", "ClaudeCodeOpen",
      "ClaudeCodeClose", "ClaudeCodeDiffAccept", "ClaudeCodeDiffDeny", "ClaudeCodeCloseAllDiffs",
      "ClaudeCodeSendText",
    },
    keys = {
      { "<leader>ac", "<cmd>ClaudeCode<CR>", desc = "Toggle Claude" },
      { "<leader>ao", "<cmd>ClaudeCodeOpen<CR>", desc = "Open Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<CR>", desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<CR>", desc = "Resume Claude" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<CR>", desc = "Continue Claude" },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<CR>", desc = "Select model" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<CR>", desc = "Add current buffer" },
      { "<leader>as", "<cmd>ClaudeCodeSend<CR>", mode = "v", desc = "Send selection" },
      {
        "<leader>as",
        "<cmd>ClaudeCodeTreeAdd<CR>",
        desc = "Add file",
        ft = { "oil", "snacks_picker_list" },
      },
      -- Claude が提案した diff (:w でも受理、:q でも拒否できる)
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<CR>", desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<CR>", desc = "Deny diff" },
      -- 並走
      { "<leader>an", "<cmd>ClaudeNew<CR>", desc = "New Claude session (this tab's cwd)" },
      { "<leader>al", "<cmd>ClaudeSessions<CR>", desc = "List Claude sessions" },
    },
    opts = {
      terminal_cmd = require("workflow.claude").cmd, -- :ClaudeNew と同じ（caffeinate 付き）
      log_level = "warn",
      focus_after_send = true,
      terminal = {
        provider = "snacks",
        split_side = "right",
        split_width_percentage = 0.4,
        -- タブごとの cwd (= worktree) で起動する
        cwd_provider = function(ctx)
          return ctx.cwd
        end,
      },
      diff_opts = {
        layout = "vertical",
        open_in_new_tab = true, -- レビューは専用タブで
      },
    },
  },
}
