# 04. 検証（停止条件）

nvim-config の変更が「完了」と言える条件。エージェントがこのリポジトリを変更するときも、これが green になるまでループする。

## 停止条件（machine-judged）

| # | 判定 | コマンド | 合格 |
|---|------|----------|------|
| V-1 | 起動エラーなし | `nvim --headless "+qa" 2>&1` | 出力が空 |
| V-2 | Lua の構文 | `luac -p` または `nvim --headless -l` で全 `lua/**/*.lua` を読み込む | exit 0 |
| V-3 | プラグイン読み込み | `nvim --headless "+Lazy! load all" "+qa" 2>&1` | エラー出力なし |
| V-4 | 起動時間 | `nvim --startuptime /tmp/st.log +qa` の最終行 | 80ms 以下（[R-20](02-requirements.md)） |
| V-5 | キーマップの衝突 | which-key の `:checkhealth which-key` | 重複の警告なし |
| V-6 | ヘルスチェック | `:checkhealth` | 使っている機能に ERROR なし |
| V-7 | スモークテスト | `nvim --headless -c "luafile scripts/smoke.lua"` | 全件 pass（独自コマンド・特殊ディレクトリ・キーマップ・verify の判定） |

**V-1〜V-4 と V-7 は `bash scripts/verify.sh` 1 本で回る。** Neovim の中からは `<Space>vv`（`:Verify` がこのスクリプトを見つけて実行する）。
V-5・V-6 は人間が `:checkhealth` で確認する。

V-7 は `scripts/claude-clipboard.lua` も別の clean Neovim で実行する。Claude のコピー出力を模擬して、メイン・追加セッションの両方で長い日本語がコピーされ、tmux の有無にかかわらず Base64 が端末表示へ漏れないことと、resume 引数・IDE 接続用環境変数が維持されることを確認する。実 Claude、OS のクリップボード、稼働中の tmux は操作しない。

`scripts/verify.sh` は実行したcheckoutを一時 `XDG_CONFIG_HOME/nvim` にリンクし、state/cache/logも一時領域へ隔離する。既存のインストール済みプラグインを利用する。V-1/V-3は空出力と終了コード0の両方が必要。V-4は正常に起動した3回分の計測が揃ったときだけ、その最小値を80msと比較する。出力のない異常終了や計測欠落はredになる。

V-7の追加回帰検査:

- `scripts/workflow-verify.lua`: 実非同期出力・worktree切替・分割ログ・保存失敗・HEAD変化・実行記録。
- `scripts/editor-regression.lua`: 同名Mermaidの並列変換・保存失敗・HTML/スキルの一覧・Go lintの実行ファイル判定。外部変換とブラウザはスタブで、実描画は別途目視する。
- `scripts/verify-regression.sh`: 無出力の異常終了・起動計測欠落を検証スクリプト自身が検出すること。
- `scripts/terminal-tests.sh`: 新規設定ディレクトリ・冪等リンク・Ghostty版判定・既存/未導入プラグイン混在時のlock復元。実プラグインは更新せず、一時Gitリポジトリで確認する。
- `scripts/ws-regression.sh`: bash/zshで同名プロジェクト・既存セッション再利用・特殊文字パスを確認する。専用の一時tmux socketだけを使い、通常のサーバーは操作しない。サンドボックスでsocket作成が禁止される場合は、実行許可のある環境で検査する。

## 人間が確認すること（機械では判定できない）

- 要求の受け入れ条件のうち、見た目に関わるもの（R-01 の表描画、R-02 の図の表示）。
- 新しく入れたキーマップが手に馴染むか。1 週間使って馴染まなければ ADR を見直す。
