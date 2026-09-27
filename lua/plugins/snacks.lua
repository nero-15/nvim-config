-- ==========================================================
-- snacks.nvim: ピッカー・エクスプローラー・ダッシュボード・画像・通知など
-- 旧 telescope / neo-tree / indent-blankline を置き換える (ADR-0004)
-- ==========================================================

-- エージェントの worktree と依存物は検索対象から外す (R-05)
local EXCLUDE = { ".git", "node_modules", ".claude/worktrees", ".next", "dist", "coverage", "test-results" }

local function pick(source, opts)
  return function()
    Snacks.picker[source](opts)
  end
end

return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      bigfile = { enabled = true },
      quickfile = { enabled = true },
      input = { enabled = true },
      notifier = { enabled = true, timeout = 3000 },
      indent = { enabled = true },
      scope = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
      -- Mermaid / 画像をバッファ内にインライン表示 (Ghostty + tmux passthrough, ADR-0002)
      -- Terminal.app では自動で無効になる
      image = { enabled = true },
      explorer = { enabled = true, replace_netrw = false }, -- ディレクトリは oil で開く
      picker = {
        enabled = true,
        sources = {
          files = { hidden = true, exclude = EXCLUDE },
          grep = { hidden = true, exclude = EXCLUDE },
          explorer = { hidden = true, exclude = vim.list_extend({ ".DS_Store" }, EXCLUDE) },
        },
      },
      dashboard = {
        enabled = true,
        preset = {
          header = table.concat({
            "Spec  →  Loop  →  Verify  →  Review",
            "人間は仕様と評価基準を書き、エージェントが回す",
          }, "\n"),
          -- セッションの入口 = 外部メモリ (docs/00-dna.md 原則 4)
          keys = {
            { icon = "󰑴 ", key = "l", desc = "Lesson (続きから)", action = ":Lesson!" },
            { icon = " ", key = "t", desc = "Tasks (引き継ぎ)", action = ":Tasks" },
            { icon = " ", key = "s", desc = "Spec Hub", action = ":Spec" },
            { icon = "󰚩 ", key = "w", desc = "Worktrees", action = ":Worktrees" },
            { icon = " ", key = "c", desc = "Claude", action = ":ClaudeCode" },
            { icon = " ", key = "f", desc = "Find file", action = ":lua Snacks.picker.files()" },
            { icon = " ", key = "g", desc = "Grep", action = ":lua Snacks.picker.grep()" },
            { icon = " ", key = "r", desc = "Restore session", action = ":lua require('persistence').load()" },
            { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          { section = "header", padding = 1 },
          { section = "keys", gap = 0, padding = 1 },
          { icon = " ", title = "Recent (this project)", section = "recent_files", cwd = true, limit = 8, indent = 2, padding = 1 },
          {
            icon = " ",
            title = "Git status",
            section = "terminal",
            enabled = function()
              return Snacks.git.get_root() ~= nil
            end,
            cmd = "git status --short --branch --renames",
            height = 8,
            padding = 1,
            ttl = 5,
            indent = 2,
          },
        },
      },
      zen = { toggles = { dim = false } },
      lazygit = {},
      terminal = {},
      scratch = {},
    },
    keys = {
      -- Find (ピッカー)
      { "<leader><space>", pick("smart"), desc = "Smart find" },
      { "<leader>ff", pick("files"), desc = "Files" },
      { "<leader>fg", pick("grep"), desc = "Grep" },
      { "<leader>fs", pick("grep_word"), desc = "Grep word / selection", mode = { "n", "x" } },
      { "<leader>fb", pick("buffers"), desc = "Buffers" },
      { "<leader>fr", pick("recent", { filter = { cwd = true } }), desc = "Recent (project)" },
      { "<leader>fR", pick("resume"), desc = "Resume last picker" },
      { "<leader>fd", pick("diagnostics"), desc = "Diagnostics" },
      { "<leader>fh", pick("help"), desc = "Help" },
      { "<leader>fk", pick("keymaps"), desc = "Keymaps" },
      { "<leader>fc", pick("commands"), desc = "Commands" },
      { "<leader>f/", pick("lines"), desc = "Lines in buffer" },
      { "<leader>fu", pick("undo"), desc = "Undo history" },
      { "<leader>fj", pick("jumps"), desc = "Jumps" },
      { "<leader>fm", pick("marks"), desc = "Marks" },
      { "<leader>fq", pick("qflist"), desc = "Quickfix list" },
      { "<leader>fS", pick("lsp_workspace_symbols"), desc = "Workspace symbols" },
      { "<leader>fn", function() Snacks.notifier.show_history() end, desc = "Notifications" },
      { "<leader>e", function() Snacks.explorer() end, desc = "Explorer" },

      -- LSP (Neovim 0.11+ の既定キー gr* をピッカー版で上書き)
      { "gd", pick("lsp_definitions"), desc = "Goto definition" },
      { "gD", pick("lsp_declarations"), desc = "Goto declaration" },
      { "grr", pick("lsp_references"), nowait = true, desc = "References" },
      { "gri", pick("lsp_implementations"), desc = "Implementation" },
      { "grt", pick("lsp_type_definitions"), desc = "Type definition" },
      { "gO", pick("lsp_symbols"), desc = "Document symbols / 見出し" },
      { "]]", function() Snacks.words.jump(vim.v.count1) end, desc = "Next reference" },
      { "[[", function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev reference" },

      -- Git
      { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
      { "<leader>gl", pick("git_log"), desc = "Git log" },
      { "<leader>gL", pick("git_log_file"), desc = "Git log (file)" },
      { "<leader>gs", pick("git_status"), desc = "Git status" },
      { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Open on GitHub", mode = { "n", "x" } },

      -- Buffer / file
      { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete buffer" },
      { "<leader>bo", function() Snacks.bufdelete.other() end, desc = "Delete other buffers" },
      { "<leader>rf", function() Snacks.rename.rename_file() end, desc = "Rename file (LSP aware)" },
      { "<leader>.", function() Snacks.scratch() end, desc = "Scratch buffer" },

      -- 表示
      { "<leader>tz", function() Snacks.zen() end, desc = "Zen (仕様を読む)" },
      { "<leader>tZ", function() Snacks.zen.zoom() end, desc = "Zoom window" },
    },
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          -- <leader>t: 表示の切り替え (which-key に状態付きで出る)
          Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>tw")
          Snacks.toggle.option("spell", { name = "Spell" }):map("<leader>ts")
          Snacks.toggle.option("relativenumber", { name = "Relative number" }):map("<leader>tn")
          Snacks.toggle.diagnostics():map("<leader>td")
          Snacks.toggle.inlay_hints():map("<leader>ti")
          Snacks.toggle.option("conceallevel", { off = 0, on = 2, name = "Conceal" }):map("<leader>tc")
          Snacks.toggle({
            name = "Virtual lines (診断を行下に)",
            get = function()
              return vim.diagnostic.config().virtual_lines ~= false
                and vim.diagnostic.config().virtual_lines ~= nil
            end,
            set = function(state)
              vim.diagnostic.config({ virtual_lines = state and { current_line = true } or false })
            end,
          }):map("<leader>tv")
        end,
      })
    end,
  },
}
