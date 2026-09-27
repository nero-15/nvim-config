# ADR-0004: 2026 年 9 月時点のプラグイン選定

- 状態: **Accepted**
- 日付: 2026-09-28
- 関連: [R-01〜R-12](../02-requirements.md)

## 背景
Neovim 0.12（2026-03 リリース）への移行に合わせて、中心的なプラグインを見直した。調査はプラグインのリポジトリを直接確認した（最終コミット・リリース・README）。

## 決定

| 役割 | 採用 | 置き換え前 | 理由 |
|------|------|-----------|------|
| ピッカー・エクスプローラー・通知・画像・ダッシュボード | **snacks.nvim** | telescope / neo-tree / indent-blankline | 1 つで揃う。claudecode / servery / live-preview / yanky がすべて snacks に対応している。最終リリースは 2026-03 と少し止まっているが安定している |
| 補完 | **blink.cmp** | nvim-cmp + LuaSnip | nvim-cmp は保守モード。blink は `snippets/`（VS Code 形式）をそのまま読める |
| LSP 導入 | **mason v2 + mason-lspconfig v2** | 同 v1 | インストール済みのサーバーを自動で `vim.lsp.enable` する。設定は `after/lsp/` |
| 構文解析 | **nvim-treesitter（main）** | 同（main） | main では `setup({ ensure_installed })` が効かない。`install()` で入れ直した（それまで自動インストールが動いていなかった） |
| Markdown（エディタ内） | **render-markdown.nvim** | 同 | 活発。markview より設定の変更が少ない |
| Mermaid（エディタ内） | **snacks.image + mmdc** | なし | Ghostty 上でインライン表示（ADR-0002） |
| Markdown / HTML（ブラウザ） | **live-preview.nvim** | なし | Node 不要。Mermaid と HTML に対応。markdown-preview.nvim は 2024 年から止まっている |
| Claude Code | **claudecode.nvim**（snacks provider） | 同 | IDE 連携（選択範囲の送信・diff の受理）。追加のセッションは独自コマンド |
| 差分レビュー | **codediff.nvim** + gitsigns | なし | 「エージェントを走らせたまま変更をレビューする」ことを目的にした設計。diffview.nvim は 2024 年から止まっている |
| worktree | **独自コマンド `:Worktrees`** | なし | 決定版のプラグインが無い。`.claude/worktrees/agent-*` の扱いが必要 |
| ファイル操作 | **oil.nvim** | neo-tree | ディレクトリをバッファとして編集できる（vimmer 定番） |
| テキストオブジェクト | **mini.ai** + treesitter-textobjects（移動・入れ替え） | treesitter-textobjects（選択も） | 次の・前の対象（`an(`, `il"`）や関数呼び出し・camelCase の 1 語まで扱える |
| 学習 | **hardtime.nvim**（ヒントのみ）+ **precognition.nvim**（切り替え） | なし | R-11 |
| undotree | **Neovim 0.12 組み込み** `:Undotree` | mbbill/undotree | 本体に入った |
| コメント | **Neovim 組み込み** `gc` | Comment.nvim | 0.10 から本体にある |

### vimmer 定番として追加したもの（R-12）
flash.nvim（既存）、harpoon（既存）、nvim-surround（既存）、**yanky**（ヤンク履歴）、**dial**（`<C-a>` の拡張）、**vim-abolish**（`crs` などの変換と `:S`）、**vim-repeat**、**treesj**（1 行 ↔ 複数行）、**mini.align**（`ga`）、**quicker.nvim**（quickfix を編集して一括反映）、**grug-far**（プロジェクト全体の置換）、**vim-fugitive**（`:G`）、**persistence.nvim**（セッション）、**inccommand=split**（`:s` のライブプレビュー、本体機能）。

### 見送ったもの
- **vim.pack**（0.12 の組み込みプラグインマネージャー）: lazy.nvim の遅延読み込みと lock ファイルに代わるものがまだ無い。
- **ui2**（0.12 の新しいメッセージ UI）: まだ実験的。
- **multicursor 系**: Vim の文法（`.`、マクロ、`cgn`）を覚える妨げになるので入れない。

## 影響
- キーマップが大きく変わった。which-key と `:help nvim-config`、[05-learning-path.md](../05-learning-path.md) で辿れるようにした。
- snacks.nvim の更新が止まったままなら、ピッカーを fzf-lua に替えることを検討する（`lua/workflow/*` は `Snacks.picker.pick` にだけ依存している）。
