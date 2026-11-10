# tasks — 現在の状態と次の一手

セッション開始時に読み、終了時に更新する。**50 行以内に保つ**（`CLAUDE.md` から毎回読み込まれる）。
終わった作業の経緯は Git 履歴に任せ、ここには「いま」と「次」だけを書く。決まりは [01](01-dev-loop.md)、合否は [04](04-verification.md)。

## 現在（2026-11-10）

- Ghostty 1.4.0 が表示、tmux がセッション保持、Neovim 0.12 が分割・仕様閲覧・Claude の操作を担当する。
- **並走する Claude の状態が見える**（R-14、[ADR-0007](adr/0007-agent-signals-and-tree-id.md)）。ステータスラインに 判断待ち `!`／完了 `✓`／作業中 `▶` の件数、`<Space>aw` で待たせている所へ移動、`<Space>aW` で新しい worktree に Claude を起動。
- **版は tree ID で特定する**（R-15）。`make check` の末尾の `tree:` 行が検証した内容を示し、`make tree-id` で照合する。エディタの Check / Verify は実行中の内容の変化を検知し、`<Space>av` で赤を Claude へ返せる。
- このリポジトリには Stop ゲートがある。green を確認した内容と違う作業木を残して Claude が終えようとすると、同じ内容については一度だけ検証を促す。
- docs を再編した。使い方は [06](06-operations.md) に集約し、時点の記録は `archive/`、教材は `guides/` へ移した。書く場所は [索引](README.md) の表で決める。

## 直近の検証

- 2026-11-10: `make check` green（V-1〜V-4・V-7〜V-10、smoke 28 件、graph 17 群）。対象の tree ID は検証の出力と Checker の報告で示す（この文書を更新すると ID が変わるため、ここには書かない）。
- 実 Claude（2.1.321）で、開始 → 作業中 → 完了 → 終了の通知が Neovim に届き、`--settings` の hook がプロジェクトの hook と併用されることを確認した。

## 未確認（人が実画面で見る）

- [ ] Claude が許可・質問で止まったとき、`!`（判断待ち）と通知が出て、`<Space>aw` でその画面へ移れる（R-14）。
- [ ] Neovim にフォーカスが無いとき、macOS の通知センターに出る。うるさければ `<Space>tA` で切る。
- [ ] Stop ゲートが実セッションで一度だけ検証を促し、二度目は終了できる（R-15）。
- [ ] `<Space>aW` で作った worktree が `<Space>gw` に並び、`<Space>al` の `<C-d>` で差分をレビューできる。
- [ ] Ghostty 上で Mermaid のインライン表示、スクロール、サイズ変更（R-02）。
- [ ] 実 Claude の選択・コピーと会話の再開（R-09）。
- [ ] 保存した audit workflow を対応する実 Runtime で実行する（mock 検査と区別して記録する）。

## 次の一手

- [ ] 新しいキー（`<Space>aw` `aW` `av` `tA`）を一週間使い、`<Space>fH` と実際の困りごとを基に見直す。開始日を記録してから数える。
- [ ] 状態通知を他のプロジェクト（sportscom-api など）で使い、判断待ちの取りこぼしや誤表示を記録する。
- [ ] tree ID と Stop ゲートを他のプロジェクトへ持ち出すか判断する。持ち出すなら `scripts/tree-id.sh` と `agent-gate.sh` をそのまま使える形にする。
- [ ] servery.nvim によるセッション保持が要件を満たすか確認し、tmux を外す場合は ADR-0003 を更新する。
- [ ] Terminal.app フォールバックと中心プラグインの見直しは、実際の利用状況と保守状況を確認した時点で判断する。

## 経過観察

- `scripts/claude-clipboard.lua` が Ghostty 更新直後に間欠的に timeout した（2026-10-29、別環境）。その後は単体 130 回・verify 3 回で再現せず、原因は未特定。
- macOS 標準の bash 3.2 は `source <(...)` で関数を読めない。テストは `eval "$(...)"` を使う（`scripts/terminal-tests.sh`）。
- 2026 年 9〜10 月の導入・統合の経緯は `git log -- docs/tasks.md` で辿れる。
