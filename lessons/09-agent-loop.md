# 09 エージェントとのループ — 仕様 → Claude → verify → レビュー

> 所要 40 分。この環境が存在する理由（docs/00-dna.md）を、手で回してみる。
> 実際のプロジェクト（例: bukatsu-one-api）を `ws` で開いてやると一番身に付く。

## ループの形

```mermaid
flowchart LR
  T[引き継ぎを読む<br/>Space st] --> S[仕様を読む・書く<br/>Space ss]
  S --> C[Claude に渡す<br/>Space ac / as]
  C --> V[停止条件<br/>Space vv]
  V -- red --> Q[赤に飛ぶ<br/>]q] --> C
  V -- green --> R[レビュー<br/>Space gd]
  R --> T
```

Ghostty なら上の図がこの画面に描かれます（Terminal.app では `<Space>mp` でブラウザに）。

## 1. 入口: 外部メモリを開く

| キー | 動作 |
|------|------|
| `<Space>st` | 引き継ぎ（`TASKS.md` など）を開く |
| `<Space>ss` | Spec Hub: 規約・引継・計画・文書・スキル・QA を一覧 |
| `<Space>sp` / `<Space>sa` | 計画だけ / ADR だけ |
| `<Space>sg` | docs/ と plans/ の中を grep |
| `<Space>sc` | CLAUDE.md |

- [ ] `<Space>st` で引き継ぎファイルを開いた
- [ ] `<Space>ss` で Spec Hub を開き、`[規約]` `[計画]` `[文書]` の並びを眺めた

## 2. Claude に渡す

| キー | 動作 |
|------|------|
| `<Space>ac` | Claude を開く / 閉じる（右に出る） |
| `<Space>as`（Visual） | 選んだ範囲を Claude に送る |
| `<Space>ab` | 今のファイルを Claude に送る |
| `Ctrl-h` / `Ctrl-l` | Claude とエディタを行き来する |
| `<Esc><Esc>` | Claude の画面をスクロールしたいとき（Normal モードへ。`i` で戻る） |

- [ ] `<Space>ac` で Claude を開き、`Ctrl-h` でエディタに戻り、`Ctrl-l` でまた Claude に行った
- [ ] 仕様の一節を `V` で選び、`<Space>as` で Claude に送った

## 3. Claude の提案を受ける・断る

Claude がファイルを変えようとすると、**専用のタブに差分**が開きます。

| キー | 動作 |
|------|------|
| `<Space>aa`（または `:w`） | 受け入れる（差分の中で手直ししてからでもよい） |
| `<Space>ad`（または `:q`） | 断る |

Claude が直接ファイルを書き換えた場合は、1 秒以内にバッファに反映され、右上に「外部で更新されました」と出ます。

- [ ] Claude に小さな変更（コメントを足すなど）を頼み、差分のタブで `<Space>aa` か `<Space>ad` を押した

## 4. 停止条件を回す

| キー | 動作 |
|------|------|
| `<Space>vv` | `make verify` / `pnpm verify` / `scripts/verify.sh` を自動で選んで実行 |
| `]q` / `[q` | 失敗した場所を順に巡る |
| `<Space>vl` | verify の全出力を見る |

結果は右上に `green ✓` か `red ✗` で出ます。赤なら quickfix が自動で開きます。

- [ ] この設定リポジトリで `<Space>vv` を押し、`green ✓` を見た

## 5. レビューする（Maker ≠ Checker）

| キー | 動作 |
|------|------|
| `<Space>gd` | 作業ツリーの変更をまとめてレビュー（左に変更ファイルの一覧） |
| `<Space>gD` | 既定ブランチ（main）との差分をレビュー |
| `]h` / `[h` | 次 / 前の変更（hunk） |
| `<Space>ghp` | その hunk をその場でプレビュー |
| `<Space>ghs` / `<Space>ghr` | hunk を stage / 元に戻す |
| `<Space>gg` | lazygit（コミット・push） |

- [ ] 何か変更がある状態で `<Space>gd` を開き、ファイルを切り替えながら差分を見た
- [ ] ファイルの中で `]h` で変更を巡り、`<Space>ghp` でプレビューした

## 6. 並走させる（worktree と複数の Claude）

| キー | 動作 |
|------|------|
| `<Space>gw` | worktree の一覧（🤖 はエージェントの worktree） |
| 　一覧で `<Enter>` | 新しいタブで開く（そのタブだけ作業ディレクトリが切り替わる） |
| 　一覧で `Ctrl-d` | main との差分をレビュー |
| 　一覧で `Ctrl-a` | その worktree で Claude を起動 |
| `<Space>an` | このタブのディレクトリで Claude をもう 1 つ起動 |
| `<Space>al` | 起動中の Claude を切り替え |

- [ ] worktree のあるプロジェクトで `<Space>gw` を開き、右側の「変更中のファイル」と「直近のコミット」を眺めた
- [ ] エージェントの worktree を `Ctrl-d` で開き、何が変わったのかをレビューした

## 卒業チェック

- [ ] 引き継ぎ → 仕様 → Claude → verify → レビュー を、キーを見ずに 1 周回せた
- [ ] 「Claude が完了と言った」ではなく、「verify が green で、自分が差分を見た」を完了の基準にしている
