# nvim-config

Neovim設定ファイル。

## セットアップ

```bash
bash setup.sh
```

これを実行すると以下が行われる:

1. 既存の `~/.config/nvim` があればバックアップ
2. このディレクトリを `~/.config/nvim` にシンボリックリンク
3. シェルにエイリアス・コマンドを登録（`v`, `ws`）
4. 不足している依存ツールを brew で一括インストール（確認あり）
5. Nerd Fontのインストール + Terminal.appのフォント変更（確認あり）

その後 `nvim` を起動すれば、プラグインは初回起動時に自動インストールされる。
（setup.sh 内でプラグイン・treesitter パーサーの一括インストールも可能）

`:Mason` からフォーマッター・リンターを手動インストール:
`stylua`, `prettier`, `php-cs-fixer`, `goimports`, `gofumpt`, `eslint_d`, `phpstan`, `golangci-lint`

## シェルコマンド

| コマンド | 機能 |
|---------|------|
| `v` | `nvim` のエイリアス。`v .` でカレントディレクトリを開く |
| `ws` | ワークスペースセレクター。fzfでプロジェクトを選び、新しいTerminal.appウィンドウでtmux+nvimを起動 |

`ws` は `~/devel/` 直下のディレクトリを自動検出する。深い階層のプロジェクトは `aliases.sh` の `extra_projects` に直接登録。

## ファイル構成

```
.
├── init.lua                      # エントリーポイント（最初に読み込まれる）
├── setup.sh                      # セットアップスクリプト
├── aliases.sh                    # シェルエイリアス・コマンド定義（v, ws）
└── lua/
    ├── config/
    │   ├── options.lua            # エディタの基本設定
    │   ├── keymaps.lua            # キーバインド定義
    │   └── autocmds.lua           # 自動コマンド
    └── plugins/
        ├── editor.lua             # neo-tree, telescope, flash, harpoon, surround, autotag, tmux-navigator, todo-comments
        ├── ui.lua                 # テーマ(tokyonight), ステータスバー(lualine), インデントガイド
        ├── lsp.lua                # LSP設定(mason, lspconfig, nvim-cmp, snippets)
        ├── treesitter.lua         # シンタックスハイライト, テキストオブジェクト
        ├── formatting.lua         # 保存時の自動フォーマット（conform.nvim）
        ├── linting.lua            # 保存時の静的解析（nvim-lint）
        └── ai.lua                 # Claude Code連携, マークダウンレンダリング
```

## キーバインド

Leaderキーは **スペース**。全キーバインドは `<Space>` を押して待てば which-key のポップアップでも確認できる。

### 基本操作

| キー | 機能 |
|------|------|
| `jk` | Insertモードを抜ける（Escの代わり） |
| `<Esc>` | 検索ハイライトを消す |
| `<Space>w` | 保存 |
| `<Space>a` | 全選択 |
| `<Space>cp` | カレントファイルのパスをコピー |

### 移動

| キー | 機能 |
|------|------|
| `C-d` / `C-u` | 半ページ移動（カーソル中央維持） |
| `n` / `N` | 検索結果ジャンプ（カーソル中央維持） |
| `s` | Flash（画面内の任意の場所にジャンプ） |
| `S` | Flash Treesitter（構文単位でジャンプ） |
| `]m` / `[m` | 次/前の関数にジャンプ |
| `]]` / `[[` | 次/前のクラスにジャンプ |
| `]t` / `[t` | 次/前のTODOコメントにジャンプ |
| `]q` / `[q` | Quickfixリストの次/前 |

### 編集

| キー | モード | 機能 |
|------|--------|------|
| `J` / `K` | ビジュアル | 選択行を上下に移動 |
| `J` | ノーマル | 行結合（カーソル位置維持） |
| `<Space>p` | ビジュアル | ペースト（レジスタ上書きなし） |
| `<Space>y` | ノーマル/ビジュアル | クリップボードにヤンク |
| `<Space>d` | ノーマル/ビジュアル | voidレジスタに削除（レジスタ汚さない） |
| `gcc` | ノーマル | コメントのON/OFF |
| `gc` | ビジュアル | 選択範囲をコメントON/OFF |
| `cs"'` | ノーマル | 囲み文字を変更（例: `"` → `'`） |
| `ds"` | ノーマル | 囲み文字を削除 |
| `ysiw"` | ノーマル | 単語を囲む |

### テキストオブジェクト（構文単位の操作）

| 操作例 | 機能 |
|--------|------|
| `daf` | 関数ごと削除 |
| `yif` | 関数の中身をヤンク |
| `vac` | クラス全体を選択 |
| `vic` | クラスの中身を選択 |
| `daa` | 引数ごと削除 |
| `via` | 引数の中身を選択 |
| `<Space>sn` | 引数を次と入れ替え |
| `<Space>sp` | 引数を前と入れ替え |

`a` = around（全体）、`i` = inner（中身）、`f` = function、`c` = class、`a` = argument

### ファイル・バッファ

| キー | 機能 |
|------|------|
| `<Space>e` | ファイルエクスプローラー（neo-tree） |
| `<Space>ff` | ファイル検索 |
| `<Space>fg` | テキスト全文検索（grep） |
| `<Space>fb` | バッファ一覧 |
| `<Space>fr` | 最近開いたファイル |
| `<Space>fs` | カーソル下の単語でgrep |
| `<Space>fd` | 診断（エラー/警告）一覧 |
| `<Space>fh` | ヘルプ検索 |
| `<Space>ft` | TODO/FIXME/HACK一覧 |
| `S-h` / `S-l` | 前/次のバッファに移動 |
| `<Space>bd` | バッファを閉じる |
| `<Space>ha` | Harpoonに追加 |
| `<Space>hh` | Harpoonメニュー |
| `<Space>1~4` | Harpoonファイル1~4に移動 |
| `<Space>u` | Undotree（変更履歴ツリー） |

### ウィンドウ

| キー | 機能 |
|------|------|
| `C-h/j/k/l` | ウィンドウ/tmuxペイン間の移動（ターミナルモードでも有効） |
| `C-Up/Down` | ウィンドウの高さを調整 |
| `C-Left/Right` | ウィンドウの幅を調整 |

### LSP（コード操作）

| キー | 機能 |
|------|------|
| `gd` | 定義元にジャンプ |
| `gD` | 宣言にジャンプ |
| `gr` | 参照一覧 |
| `gi` | 実装にジャンプ |
| `K` | ドキュメント表示（ホバー） |
| `<Space>ca` | コードアクション |
| `<Space>cr` | リネーム |
| `<Space>cd` | 行の診断を表示 |
| `<Space>cf` | バッファをフォーマット |
| `]d` / `[d` | 次/前の診断（エラー/警告） |

### AI

| キー | 機能 |
|------|------|
| `<Space>ac` | Claude Codeの開閉（`--dangerously-skip-permissions` で起動） |
| `<Space>ao` | Claude Codeを開く |
| `<Space>as` | 選択範囲をClaude Codeに送信（ビジュアルモード） |

## 自動フォーマット

保存時に自動でフォーマットが走る（conform.nvim）。

| 言語 | フォーマッター |
|------|-------------|
| Lua | stylua |
| TS/JS/JSON/CSS/SCSS/HTML/YAML/Markdown | prettier |
| PHP | php-cs-fixer |
| Go | goimports + gofumpt |

## リンター

保存時・読み込み時に静的解析が走る（nvim-lint）。リンターが未インストールの場合は自動スキップ。

| 言語 | リンター |
|------|---------|
| TS/JS | eslint_d |
| PHP | phpstan |
| Go | golangci-lint |

## 自動コマンド

| 動作 | 説明 |
|------|------|
| ファイル変更の自動反映 | 1秒ごとにチェック。Claude Codeの変更がリアルタイムでエディタに反映される |
| ヤンク時ハイライト | コピーした範囲が一瞬光る |
| カーソル位置の復元 | ファイルを開くと前回の位置に戻る |
| ターミナル自動Insert | ターミナルを開くとすぐ入力できる |
| 末尾空白の自動削除 | 保存時にトリム |
| Markdown折り返し | Markdownファイルは行を折り返して表示 |

## 対応言語（LSP）

| 言語 | LSPサーバー |
|------|-----------|
| Lua | lua_ls |
| TypeScript/JavaScript/React | ts_ls |
| HTML | html |
| CSS/SCSS | cssls |
| Emmet (HTML/JSX展開) | emmet_language_server |
| Go | gopls |
| PHP | intelephense |

`:Mason` で他の言語のLSPも追加できる。

## React / Next.js サポート

- **ts_ls**: TSX/JSX の型チェック・補完・定義ジャンプ
- **emmet_language_server**: `div.container>ul>li*3` のような省略記法をJSX内でも展開
- **nvim-ts-autotag**: HTML/JSXタグの自動閉じ・ペアリネーム
- **treesitter**: TSX/JSX/HTML/CSS/SCSS のシンタックスハイライト
- **eslint_d**: JSX/TSX のリント
- **prettier**: JSX/TSX/CSS/SCSS のフォーマット

## スニペット

friendly-snippets による各言語のスニペットが補完候補に表示される。
Insertモードで `Tab` でスニペット展開・次のプレースホルダーに移動。

## 必要なもの

- **Neovim 0.11以上**
- **git, node, ripgrep, fd** （検索系ツール）
- **tree-sitter-cli** （treesitter パーサーのコンパイルに必要）
- **fzf** （wsコマンドのプロジェクト選択に使用）
- **Claude Code** （AI連携）
- **tmux** （推奨、必須ではない）

`setup.sh` が不足ツールを検出し、brew での一括インストールを提案する。
