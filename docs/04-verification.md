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
| V-7 | スモークテスト | `nvim --headless -c "luafile scripts/smoke.lua"` | 全件 pass（独自コマンド・特殊ディレクトリ・キーマップ・verify の判定と quickfix・lint の判定） |
| V-8 | シェル関数 | `ws` を `WS_DRY_RUN=1` で同名の別ディレクトリに対して実行 | 別のセッション名になり、同じパスなら同じ名前 |

**V-1〜V-4 と V-7・V-8 は `bash scripts/verify.sh` 1 本で回る。** Neovim の中からは `<Space>vv`（`:Verify` がこのスクリプトを見つけて実行する）。
V-5・V-6 は人間が `:checkhealth` で確認する。

## 人間が確認すること（機械では判定できない）

- 要求の受け入れ条件のうち、見た目に関わるもの（R-01 の表描画、R-02 の図の表示）。
- 新しく入れたキーマップが手に馴染むか。1 週間使って馴染まなければ ADR を見直す。
