# 04. 検証（停止条件）

nvim-config の変更が「完了」と言える条件。エージェントがこのリポジトリを変更するときも、これが green になるまでループする。
状態: current。検査の内容・範囲の正本。役割と差し戻しは [01-dev-loop.md](01-dev-loop.md)。

## 反復と節目

| 場面 | エディタ | 選ぶコマンド |
|---|---|---|
| 日々の反復 | `:Check` / `<Space>vc` | package.jsonの`scripts.check` → Makefileの`check:` → `scripts/check.sh` |
| 全体の確認 | `:Verify` / `<Space>vv` | package.jsonの`scripts.verify` → Makefileの`verify:` → `scripts/verify.sh` |
| 記録を見る | `:VerifyLog` / `<Space>vl` | 直前の実行。check/verifyのmode・実行元・コマンド・HEAD・時刻・終了コード |

未定義のモードは通知して中止し、もう一方のモードで代用しない。各プロジェクトでcheck/verifyの意味が違うため、そのリポジトリの停止条件を読む。**nvim-config自体は検査が短く、`make check` と `make verify` が同じスクリプトを呼ぶ**。速さのためにV-1〜V-3を省かない。

## 停止条件（machine-judged）

| # | 判定 | コマンド | 合格 |
|---|------|----------|------|
| V-1 | 起動エラーなし | `nvim --headless "+qa" 2>&1` | exit 0 かつ出力が空 |
| V-2 | Lua の構文 | init.lua / lua / plugin / after / ftdetect / scripts の全Luaをclean Neovimの`loadfile`で検査 | 全件 exit 0 |
| V-3 | プラグイン読み込み | `nvim --headless "+Lazy! load all" "+qa" 2>&1` | exit 0 かつ出力が空 |
| V-4 | 起動時間 | `--startuptime` の `NVIM STARTED` を正常起動3回で計測 | 3件揃い最小値が80ms 以下（[R-20](02-requirements.md)） |
| V-5 | キーマップの衝突 | which-key の `:checkhealth which-key` | 重複の警告なし |
| V-6 | ヘルスチェック | `:checkhealth` | 使っている機能に ERROR なし |
| V-7 | スモークテスト | `nvim --headless -c "luafile scripts/smoke.lua"` | 全件 pass（独自コマンド・特殊ディレクトリ・キーマップ・verify の判定と quickfix・lint の判定） |
| V-8 | シェル関数 | `ws` を `WS_DRY_RUN=1` で同名の別ディレクトリに対して実行 | 別のセッション名になり、同じパスなら同じ名前 |
| V-9 | 文書の入口 | `make doc-links-check` | ファイルリンク切れなし・全docsのmd/htmlがdocs/README.mdから辿れる |
| V-10 | 実行グラフの境界 | `node scripts/graph-tests.mjs` | 役割ガード・監査の分岐/版一致/並列数/未確認・失敗処理が合格 |

**V-1〜V-4 と V-7〜V-10 は `make verify`（`bash scripts/verify.sh`）1 本で回る。** Neovim の中からは `<Space>vv`。V-10にはNode.jsが必要（setup.shの依存確認対象）。
V-5・V-6 は人間が `:checkhealth` で確認する。

V-7 は `scripts/claude-clipboard.lua` も別の clean Neovim で実行する。Claude のコピー出力を模擬して、メイン・追加セッションの両方で長い日本語がコピーされ、tmux の有無にかかわらず Base64 が端末表示へ漏れないことと、resume 引数・IDE 接続用環境変数が維持されることを確認する。実 Claude、OS のクリップボード、稼働中の tmux は操作しない。

`scripts/verify.sh` は実行したcheckoutを一時 `XDG_CONFIG_HOME/nvim` にリンクし、state/cache/logも一時領域へ隔離する。既存のインストール済みプラグインを利用する。V-1/V-3は空出力と終了コード0の両方が必要。V-4は正常に起動した3回分の計測が揃ったときだけ、その最小値を80msと比較する。出力のない異常終了や計測欠落はredになる。

V-7の追加回帰検査:

- `scripts/workflow-verify.lua`: 実非同期出力・worktree切替・分割ログ・保存失敗・HEAD変化・実行記録。
- `scripts/doc-links-regression.lua`: ファイルリンク切れと孤児の拒否、相対リンク・HTML・コード例の扱い。
- `scripts/editor-regression.lua`: 同名Mermaidの並列変換・保存失敗・HTML/スキルの一覧・Go lintの実行ファイル判定。外部変換とブラウザはスタブで、実描画は別途目視する。
- `scripts/verify-regression.sh`: 無出力の異常終了・起動計測欠落を検証スクリプト自身が検出すること。
- `scripts/terminal-tests.sh`: 新規設定ディレクトリ・冪等リンク・Ghostty版判定・既存/未導入プラグイン混在時のlock復元。実プラグインは更新せず、一時Gitリポジトリで確認する。
- `scripts/ws-regression.sh`: bash/zshで同名プロジェクト・既存セッション再利用・特殊文字パスを確認する。専用の一時tmux socketだけを使い、通常のサーバーは操作しない。サンドボックスでsocket作成が禁止される場合は、実行許可のある環境で検査する。

## 人間が確認すること（機械では判定できない）

V-9は外部URLの疎通・節アンカー・文書の意味的な正しさを検査しない。V-10はmock runtimeで制御フローを検査するもので、Claudeの実課金セッションでの監査実行やhook読込を保証しない。Claude用の設定はCodexには自動適用されない。

- 要求の受け入れ条件のうち、見た目に関わるもの（R-01 の表描画、R-02 の図の表示）。
- 新しく入れたキーマップが手に馴染むか。1 週間使って馴染まなければ ADR を見直す。
