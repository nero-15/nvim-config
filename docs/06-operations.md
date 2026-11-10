# 06. 運用ガイド — 日々の使い方と困ったとき

使い方と運用上の注意の正本。キーを覚える順番は [05](05-learning-path.md)、役割と受け渡しの決まりは [01](01-dev-loop.md)、検査の合否は [04](04-verification.md)。エディタの中では `:help nvim-config`（`<Space>H`）で同じキーを引ける。

## 一日の流れ

| 目的 | 入口 | 対象 |
|---|---|---|
| 続きから始める | `<Space>st` | プロジェクトのタスク記録。nvim-config は [tasks](tasks.md) |
| 仕様・教材を読む | `<Space>ss` / `<Space>sg` | Markdown・HTML・Mermaid・スキル・役割定義の原本 |
| 図を見る | `<Space>mp` | 現在のファイルのプレビュー |
| エージェントを動かす | `<Space>ac` / `<Space>an` / `<Space>aW` | メイン / 追加 / 新しい worktree で隔離 |
| 待たせている所へ行く | `<Space>aw` / `<Space>al` | 判断待ち → 完了・未読の順に移動 / 状態つきの一覧 |
| 停止条件を回す | `<Space>vc` / `<Space>vv` / `<Space>vl` | 日常の check / 全体の verify / 実行記録 |
| 赤をエージェントへ返す | `<Space>av` | 失敗したログの場所と指示を Claude の入力欄へ |
| 差分をレビューする | `<Space>gd` / `<Space>gD` / `<Space>gw` | 作業木 / 既定ブランチとの差 / worktree |

## エージェントを並走させる

### 起動する

- `<Space>ac` はメインの Claude（claudecode.nvim。選択範囲の送信、diff の受理・拒否ができる）。
- `<Space>an` は、今のタブの作業ディレクトリで Claude を追加する。
- `<Space>aW`（`:ClaudeWorktree 名前`）は、新しい git worktree を作ってそこで Claude を始める。互いのファイルを書き換えない、独立した仕事に使う。出来た worktree は `<Space>gw` に並ぶ。

### 状態を見る

Neovim から起動した Claude は、状態をエディタへ知らせる。

| 表示 | 状態 | 意味 |
|---|---|---|
| `!` | 判断待ち | 許可や回答を求めている。あなたが動かないと進まない |
| `✓` | 完了・未読 | 応答を終えた。まだその画面を見ていない |
| `▶` | 作業中 | 進行中。待つか、別の仕事をする |
| `·` | 待機 | 応答済みで、既に見た |

- ステータスライン右側に `󰚩 !1 ✓1 ▶2` のように件数が出る。判断待ちがあると橙色になる。
- タブが複数あるとき、その場所で人を待つセッションがあるタブに `!` か `✓` が付く。
- 判断待ち・完了になった瞬間、その画面を見ていなければ右上に通知が出る。Neovim にフォーカスが無いときは macOS の通知センターにも出る（`<Space>tA` で切り替え）。
- 完了したセッションは、その画面に入ると既読（待機）になる。判断待ちは、Claude が再び動き出すまで残る。

### 待たせている所へ行く

- `<Space>aw`（`:ClaudeNext`）は、判断待ち → 完了・未読の順で、最も長く待っているセッションの画面へ移る。別のタブに出ていればそのタブへ移り、隠れていれば開く。
- `<Space>al`（`:ClaudeSessions`）は状態・経過時間・直近の発言つきの一覧。`<CR>` で画面へ、`<C-t>` でそのセッションの作業ディレクトリを新しいタブで開き、`<C-d>` で既定ブランチとの差分をレビューする。

### 仕組みと注意

- 状態は Claude Code の hook が送る。hook は起動コマンドの `--settings` で足しており、`~/.claude/settings.json` やプロジェクトの設定は書き換えない。プロジェクト側の hook とも併用される。
- 対象は Neovim の中で起動したセッションだけ。外の端末で起動した Claude は表示されない。
- 起動コマンドの変更は、起動済みの Claude には反映されない。作業の区切りで終了し、`<Space>ar`（resume）で会話を再開する。
- check が ignore されない生成物を作るプロジェクトでは、実行のたびに内容が変わるため「再検証してください」になる。生成物を `.gitignore` に入れる。
- 許可を求められたあと拒否した場合など、次の区切り（応答の完了や新しい入力）まで「判断待ち」の表示が残ることがある。
- 通知が届かない環境では何も表示されないだけで、Claude の起動と操作は変わらない。

## 検証と証拠

- `<Space>vc`（`:Check`）と `<Space>vv`（`:Verify`）は、対象プロジェクトが明示した定義だけを実行する（探す順番は [04](04-verification.md#反復と節目)）。未定義なら通知して中止し、二つは同時に実行しない。保存に失敗したら中止する。
- 赤なら quickfix が開き、`]q` / `[q` で失敗箇所を巡る。実行中に `<Space>gw` で別の worktree へ移っても、診断は開始した worktree のファイルを指す。
- `<Space>vl`（`:VerifyLog`）は直前の実行記録。mode・実行元・コマンド・開始終了時刻・HEAD・**tree ID**・終了コード・全出力を見られる。
- tree ID は作業木の内容（未コミット・未追跡を含み、ignore を除く）の ID。実行中に HEAD か内容が変わると、exit 0 でも green と表示せず再検証を促す。エージェントが検証の最中に書き換えた結果を、完了の証拠にしないためである。
- `<Space>av`（`:VerifySend`）は、直前の赤い結果を **メインの Claude の入力欄へ入れる**（送信はしない）。方針を書き足してから Enter で渡す。ログは Neovim の状態ディレクトリ（`stdpath("state")/verify/`）に保存され、プロジェクトの作業木を汚さない。
- nvim-config 自身では、`make check` の末尾に `tree:` 行が出る。Maker と Checker はこの値で同じ版を照合する（[01](01-dev-loop.md)）。`make tree-id` でいつでも現在の値を確認できる。

## 仕様と成果物を読む

- `<Space>ss`（Spec Hub）は規約・引き継ぎ・計画・文書に加え、`docs/**/*.html`・`docs/**/*.mmd`、`.claude/` の役割定義・保存した workflow・設定、各エージェントのスキル（`.claude/skills/`・`.agents/skills/`・`.codex/skills/` の `SKILL.md`）を一覧する。`<Space>sg` の検索も同じ形式を対象にする。
- HTML や Mermaid は `<Space>mp` でブラウザに表示する。Ghostty では Markdown 内の Mermaid がその場に描画される。
- 単独の `.mmd` は保存成功後に変換する。同名の図を複数の worktree で開いても、プレビューの出力は混ざらない。

## 端末（Ghostty・tmux・ws）

役割分担は Ghostty が表示、tmux がプロジェクトのセッション保持、Neovim が分割・移動・Claude の操作（[ADR-0003](adr/0003-multiplexer-strategy.md)）。

- `ws` は正規化したフルパスでセッションを区別する。`client-a/api` と `client-b/api` は別のセッションになり、シンボリックリンク経由では同じセッションへ戻る。従来の短い名前のセッションは作成元が一致するときだけ再利用し、既存のセッションは削除しない。
- `bash setup.sh --upgrade-ghostty` は Homebrew 管理の Ghostty だけを更新する。シェル設定やプラグインの更新は伴わない。Homebrew は更新中に起動中の Ghostty を閉じて再起動する。`bash setup.sh --check-ghostty` で版と設定を検査できる。
- スクロールバック圧縮と非表示タブの省メモリは Ghostty 1.4 の既定値を使う。tmux と Neovim の履歴は別なので、履歴を無制限に増やさない。
- SSH 接続は必要なときに `ghostty +ssh user@host`。自動 alias は設定しない。`⌘↑` / `⌘↓` はプロンプト間の移動。

## Claude の会話を選択・コピーする

- `<Space>ac` と `<Space>an` で起動した Claude は、通常のドラッグ選択とコピーを使える。
- Neovim 内の Claude には外側の `TMUX` / `TMUX_PANE` を渡さない。tmux 用のコピー制御コードが内蔵端末で Base64 の文字列として露出するのを防ぐためである（R-09）。
- 一時的な回避が必要なら、Claude の `/config` で **Copy on select** をオフにし、`Shift` を押しながらドラッグして Ghostty 側で選択・コピーする。Neovim の複数ウィンドウをまたがないよう注意する。

## 設定を変えたあと、どこから反映されるか

| 変えたもの | 反映される時点 |
|---|---|
| Ghostty の版・設定 | 次に起動した Ghostty |
| Neovim の設定（このリポジトリ） | 新しく起動した Neovim |
| Claude の起動コマンド・状態通知の hook | 新しく起動した Claude（会話は `<Space>ar` で再開） |
| `aliases.sh`（`ws` など） | 開き直したシェル、または `source` したシェル |

作業中のエージェントを終了させず、区切りで再起動する。

## 困ったとき

| 症状 | 確認すること |
|---|---|
| Check / Verify が始まらない | 保存できないバッファが無いか。保存先や権限を直してから再実行する |
| `green` にならず「再検証してください」と出る | 実行中に内容か HEAD が変わった。エージェントの書き込みが止まってから再実行する |
| Claude の状態が出ない | そのセッションは Neovim の中で、設定更新後に起動したものか。`<Space>al` に並ぶか |
| `<Space>av` で渡せない | メインの Claude（`<Space>ac`）が起動しているか。直前の結果が赤か |
| Claude が終了前に検証を求められる | nvim-config の Stop ゲート。`make check` を実行するか、未検証で残す理由を報告させる（[01](01-dev-loop.md)） |
| Xcode 更新後にビルドやリンクが失敗する | 更新の完了とライセンスの状態を先に確認する |
