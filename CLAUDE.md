# Claude Code Configuration - nvim-config

## Project Overview
AI 駆動（仕様駆動）開発のための Neovim + tmux 環境。人間は仕様・ループ・評価基準の設計者で、
エディタの主用途は「書く」より「読む・判断する・エージェントの舵を切る」。

**まず [docs/00-dna.md](docs/00-dna.md) を読む。** 設計書の索引は [docs/README.md](docs/README.md)。

## Stack
- Neovim 0.12+（`vim.lsp.config` / `vim.lsp.enable` の新 API）
- Plugin manager: lazy.nvim（`lazy-lock.json` でバージョン固定）
- tmux 3.6+ / macOS / zsh
- `setup.sh` がシンボリックリンク（`~/.config/nvim` → このリポジトリ）と依存ツールの導入を担う

## Layout
- `init.lua` → `lua/config/{options,keymaps,autocmds}.lua` → `lua/plugins/*.lua`（ドメインごと）
- `docs/` は設計書（Neovim は読まない）。`doc/` は `:help nvim-config` のヘルプ（Neovim が読む）。混同しない
- `scripts/` は停止条件・回帰検査・版 ID・Claude の hook。`.claude/` は役割定義・監査 workflow・このリポジトリの hook
- runtimepath の特殊ディレクトリ: `after/ftplugin/`（filetype 設定）・`after/lsp/`（LSP 設定）・`ftdetect/`・`snippets/`・`doc/`。使い分けは [docs/03-architecture.md](docs/03-architecture.md)

## Rules
- 変更は [docs/02-requirements.md](docs/02-requirements.md) の要求 ID（`R-xx`）に紐づける。
- 文書を足す・直す前に [docs/README.md](docs/README.md) の「書く場所」の表で置き場所を決める。同じ決まりを二か所に書かない。
- プラグインの採用・廃止・大きな方針変更は [docs/adr/](docs/adr/) に ADR を書く。
- 新しいキーマップは which-key のグループに入れ、`desc` を必ず付ける。
- 外部ツールが無い環境でもエラーを出さない（`vim.fn.executable` で確認してから使う）。
- Leader は `<Space>`。`<leader>a` は AI（Claude Code）用に予約済み。

## Stop conditions (machine-judged)
[docs/04-verification.md](docs/04-verification.md) を参照。`make check` が green であること。
完了の報告には、green と出力末尾の `tree:` 行（検証した作業木の内容の ID）をセットで示す。赤や未検証で終える場合は、その事実と理由を書く。
green を確認した内容と違う作業木を残して終えようとすると、Stop hook が同じ内容については一度だけ検証を促す（忘れ防止。権限境界ではない）。

## Execution graph
役割・並列化・作業パケット・差し戻しの正は [docs/01-dev-loop.md](docs/01-dev-loop.md)。
Claudeの役割は `.claude/agents/maker.md` / `checker.md`、横断監査は `.claude/workflows/audit.js`。
役割ガードは誤操作防止であり、Bashの完全な隔離ではない。通常のClaude起動が自動でMaker/Checkerへ変わるわけではない。
Checkerは編集せず対象版の証拠を統括へ返す。明示指示なしにPRコメント等を送信しない。
版は `make tree-id` の tree ID で照合する（HEAD の SHA は未コミットの変更を区別しない）。

## External memory
[docs/tasks.md](docs/tasks.md) を下で読み込む。終了時に更新し、50 行以内に保つ（経緯は Git 履歴へ）。

@docs/tasks.md
