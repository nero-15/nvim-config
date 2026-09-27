-- ==========================================================
-- 独自コマンド: 仕様駆動 × ループエンジニアリングの操作をコマンド化
-- plugin/ は起動時に自動で読み込まれる runtimepath の特殊ディレクトリ
-- 実装は lua/workflow/*.lua (呼ばれたときに初めて読み込む)
-- ==========================================================

local function command(name, fn, desc, opts)
  vim.api.nvim_create_user_command(name, fn, vim.tbl_extend("force", { desc = desc }, opts or {}))
end

local function call(mod, fn, ...)
  local args = { ... }
  return function()
    require("workflow." .. mod)[fn](unpack(args))
  end
end

-- 停止条件
command("Verify", call("verify", "run"), "停止条件 (make/pnpm verify) を実行して quickfix へ")
command("VerifyLog", call("verify", "show_log"), "直前の verify の全出力を開く")

-- 外部メモリ (仕様・計画・タスク)
command("Spec", call("spec", "pick"), "Spec Hub: 規約・引継・計画・文書を一覧")
command("Tasks", call("spec", "tasks"), "引き継ぎファイル (TASKS.md 等) を開く")
command("Adr", call("spec", "adr"), "ADR を一覧")
command("Plans", call("spec", "pick", { kinds = { "plan" }, title = "Plans" }), "計画ファイルを一覧")
command("SpecGrep", call("spec", "grep"), "docs/ と plans/ の中を grep")

-- エージェントの worktree と Claude
command("Worktrees", call("worktree", "pick"), "worktree を一覧して開く / 差分レビュー / Claude 起動")
command("ClaudeNew", call("claude", "new"), "現在のタブの cwd で Claude を追加起動")
command("ClaudeSessions", call("claude", "pick"), "起動中の Claude を切り替え")

-- プレビュー
command("Preview", call("preview", "open"), "md / html / mermaid / pdf をブラウザ等でプレビュー")
command("PreviewStop", call("preview", "close"), "ライブプレビューを止める")

-- レッスン (lessons/*.md を自分用にコピーして学ぶ)
command("Lesson", function(opts)
  local lesson = require("workflow.lesson")
  if opts.args == "" and opts.bang then
    lesson.open() -- :Lesson! = 続きから (未完了の最初のレッスン)
  elseif opts.args == "" then
    lesson.pick()
  else
    lesson.open(opts.args)
  end
end, "レッスン一覧 / :Lesson 3 で 3 番を開く / :Lesson! で続きから", {
  nargs = "?",
  bang = true,
  complete = function()
    return require("workflow.lesson").complete()
  end,
})
command("LessonReset", function(opts)
  require("workflow.lesson").reset(opts.args)
end, "レッスンの自分用コピーを原本に戻す", { nargs = "?" })

-- タブライン (タブごとの worktree 名)
require("workflow.tabline").setup()
