# 05. Vim 学び直しロードマップ

「Vim のコマンドにまだ慣れていない」ことを前提に、使う頻度と効果の大きい順に並べる。
各段階は **1 週間ほど意識して使い、指が覚えたら次へ**進む。

> 方針: 設定で便利にしすぎて Vim の素の力が身に付かない、という状態を避ける。
> 素の Vim の文法 → それを増幅するプラグイン、の順で覚える。
>
> エディタの中では `:help nvim-config`（`<Space>H`）で同じ内容を引ける。
> 補助輪: `<Space>th` で hardtime（`jjjj` などにヒントが出る）、`<Space>tp` で precognition（行内の跳び先が見える）。
> 1 週間ごとに `<Space>fH`（hardtime の集計）で自分の悪い癖を確認する。

## Stage 0: 文法を知る（最重要）

Vim の操作は **「動詞 + 対象」** の組み合わせ。覚えるのは組み合わせではなく部品。

| 動詞 | 意味 | 対象（モーション / テキストオブジェクト） | 意味 |
|------|------|------------------------------------------|------|
| `d` | 削除 | `w` / `b` / `e` | 単語単位 |
| `c` | 削除して入力 | `iw` / `aw` | 単語の中 / 単語ごと |
| `y` | コピー | `i"` / `a(` / `it` | 引用符・括弧・タグの中 |
| `v` | 選択 | `ip` | 段落 |
| `>` `<` | インデント | `if` / `af` | 関数の中 / 関数ごと（treesitter） |
| `gc` | コメント | `f{文字}` / `t{文字}` | その文字まで |

例: `ci"` = 引用符の中を書き換え、`dap` = 段落ごと削除、`yif` = 関数の中身をコピー。

## Stage 1: 移動をやめる、跳ぶ
- `jjjj` の代わりに: 相対行番号を見て `5j`、`}` / `{`（段落）、`s`（flash で 2 文字ジャンプ）
- `w` 連打の代わりに: `f` / `t` + `;` で繰り返し
- `%` 対応する括弧、`gd` 定義へ、`<C-o>` / `<C-i>` 戻る・進む

## Stage 2: 繰り返しの力
- `.` 直前の変更を繰り返す（最強のコマンド）
- `*` カーソル下の単語を検索 → `cgn` で置換 → `.` で次々と
- マクロ: `qa` で記録開始 → 操作 → `q` で終了 → `@a` で再生、`@@` で再実行

## Stage 3: 複数ファイルを扱う
- quickfix: grep の結果を quickfix に送る → `]q` で巡回 → `:cdo s/old/new/` で一括置換
  - `<Space>xq` で quickfix を開き、行を直接書き換えて `:w` しても一括反映できる（quicker.nvim）
- プロジェクト全体の置換: `<Space>rr`（grug-far。結果を見ながら置換）
- ファイルをバッファとして編集: `-` で親ディレクトリを開き、行を書き換えて `:w` → リネーム・移動・削除（oil.nvim）
- マーク: `ma` で印 → `'a` で戻る（大文字 `mA` はファイルをまたぐ）
- 変換: `crs`（snake_case）`crc`（camelCase）、`:S/facility{,ies}/school{,s}/g`（単数・複数をまとめて置換）

## Stage 4: 仕様駆動の読み書き
- 入口: `<Space>st`（引き継ぎ）→ `<Space>ss`（Spec Hub）→ `<Space>gw`（worktree）
- Markdown: `<Space>mo` 見出し一覧、`]]` / `[[` 見出し間の移動、`<Space>mx` チェックボックス
- 雛形: Insert モードで `spec` / `adr` / `plan` / `mflow` などを入力して補完から選ぶ
- 図: Ghostty ならそのまま表示。ブラウザで見るなら `<Space>mp`
- レビュー: `<Space>gd`（全体）→ `]h` で hunk を巡回 → `<Space>ghs` で stage
- 日常の確認: `<Space>vc`（`:Check`）、全体検証: `<Space>vv`（`:Verify`）→ 赤なら `]q` で直接飛ぶ

### CheckとVerifyを使い分ける

- `<Space>vc`は対象プロジェクトの明示的な `check` を実行する。`package.json` の `scripts.check` → Makefileの `check:` → `scripts/check.sh` の順に探す。
- `check`未定義なら通知する。勝手にVerifyやtypecheckを実行しない。nvim-config自身は `make check` と `make verify` が同じ全体検証を使う。
- Check/Verifyは同時には実行しない。保存に失敗すれば中止する。
- `<Space>vl`（`:VerifyLog`）は両者共用の直前ログ。modeと実行元を確認する。scratch bufferなので、引き継ぎの証拠は別途記録する。
- 検査内容と合否は [04-verification.md](04-verification.md)、担当間の受け渡しは [01-dev-loop.md](01-dev-loop.md) を参照する。

### 複数エージェントの成果を確認する

- `<Space>ss`（Spec Hub）は Markdown に加えて `docs/**/*.html`・`docs/**/*.mmd` も一覧する。最近の調査HTMLを選び、`<Space>mp` でブラウザ表示できる。`<Space>sg` の仕様検索も同じ形式を対象にする。
- Claude Codeの役割定義・保存したworkflow・hook設定もSpec Hubから探せる。Codexではこれらの権限制限は自動適用されないため、担当依頼で所有範囲を明示する。
- スキルの入口は `.claude/skills/`・`.agents/skills/`・`.codex/skills/` 内の `SKILL.md`。which-key の `<Space>s` から辿れる。
- 保存できないバッファがある場合は、保存先や権限を確認してから検証を再実行する。
- 実行中に `<Space>gw` で別 worktree へ移っても、診断は開始した worktree のファイルを指す。分割されて届いたログも改行までつないで解析する。
- `<Space>vl`（`:VerifyLog`）で実行元・コマンド・開始終了時刻・HEAD・終了コードを見る。HEADが実行中に変わったら再検証する。未コミット編集はHEADでは区別できないため、エージェントがさらに編集した後は再実行する。
- 単独の `.mmd` は保存成功後に変換する。同名の図を複数worktreeで開いても、プレビューの出力は混ざらない。
- `ws` は正規化したフルパスでセッションを区別する。`client-a/api` と `client-b/api` は別セッションになり、シンボリックリンク経由では同じセッションへ戻る。従来の短い名前のセッションも作成元が一致するときだけ再利用し、既存セッションは削除しない。シェルを開き直すか、このリポジトリの `aliases.sh` を `source` すると反映される。

### Ghostty 1.4 の運用

- `bash setup.sh --upgrade-ghostty` は Homebrew 管理の Ghostty だけを更新する。シェル設定やプラグインの更新は伴わない。`bash setup.sh --check-ghostty` で版と設定を検査できる。
- スクロールバック圧縮・非表示タブの省メモリは1.4の既定値を使う。tmuxとNeovim自身の履歴は別なので、履歴を無制限に増やさない。
- SSH接続は必要なときに `ghostty +ssh user@host`。自動aliasは設定しない。
- `⌘↑` / `⌘↓` はプロンプト間移動。選択時のシステムクリップボードへのコピーは既存設定のまま。
- Ghostty更新は次のアプリ起動に、Neovim設定は新しく起動するNeovimに反映される。作業中のエージェントを終了させず、区切りで再起動する。

### Claude の会話を選択・コピーする

- `<Space>ac`（メイン）と `<Space>an`（追加）で起動した Claude は、通常のドラッグ選択・コピーを使える。
- Neovim 内の Claude には外側の `TMUX` / `TMUX_PANE` を渡さない。tmux 用のコピー制御コードが内蔵端末で Base64 の文字列として露出するのを防ぐ（R-09）。Neovim 本体や外側の tmux の設定は変えない。
- この設定変更は起動済みの Claude には反映されない。作業の区切りで Claude を終了し、Neovim を起動し直して `<Space>ar`（resume）で会話を再開する。追加セッションは `<Space>an` で起動後に `/resume` を使う。
- 再起動までの一時回避は、Claude の `/config` で **Copy on select** をオフにし、`Shift` を押しながらドラッグして Ghostty 側で選択・コピーする。Neovim の複数ウィンドウをまたがないよう注意する。

---

各 Stage のキーマップは which-key（`<Space>` を押して待つ）からも辿れる。
設定のアップデートで入った機能は、ここに追記していく。
