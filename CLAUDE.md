# Claude Code Configuration - nvim-config

## Project Overview
AI 駆動（仕様駆動）開発のための Neovim + tmux 環境。人間は仕様・ループ・評価基準の設計者で、
エディタの主用途は「書く」より「読む・判断する・エージェントの舵を切る」。

**まず [docs/00-dna.md](docs/00-dna.md) を読む。** 設計書の索引は [docs/README.md](docs/README.md)。

## Stack
- Neovim 0.11+（`vim.lsp.config` / `vim.lsp.enable` の新 API）
- Plugin manager: lazy.nvim（`lazy-lock.json` でバージョン固定）
- tmux 3.6+ / macOS / zsh
- `setup.sh` がシンボリックリンク（`~/.config/nvim` → このリポジトリ）と依存ツールの導入を担う

## Layout
- `init.lua` → `lua/config/{options,keymaps,autocmds}.lua` → `lua/plugins/*.lua`（ドメインごと）
- `docs/` は設計書（Neovim は読まない）。`doc/` は `:help nvim-config` のヘルプ（Neovim が読む）。混同しない
- runtimepath の特殊ディレクトリ: `after/ftplugin/`（filetype 設定）・`after/lsp/`（LSP 設定）・`ftdetect/`・`snippets/`・`doc/`。使い分けは [docs/03-architecture.md](docs/03-architecture.md)

## Rules
- 変更は [docs/02-requirements.md](docs/02-requirements.md) の要求 ID（`R-xx`）に紐づける。
- プラグインの採用・廃止・大きな方針変更は [docs/adr/](docs/adr/) に ADR を書く。
- 新しいキーマップは which-key のグループに入れ、`desc` を必ず付ける。
- 外部ツールが無い環境でもエラーを出さない（`vim.fn.executable` で確認してから使う）。
- Leader は `<Space>`。`<leader>a` は AI（Claude Code）用に予約済み。

## Stop conditions (machine-judged)
[docs/04-verification.md](docs/04-verification.md) を参照。最低限 `nvim --headless "+qa"` がエラー出力なしで終了すること。

## External memory
セッション開始時に [docs/tasks.md](docs/tasks.md) を読み、終了時に更新する。
