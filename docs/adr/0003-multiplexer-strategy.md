# ADR-0003: 画面分割のレイヤーを tmux と Neovim のどちらに寄せるか

- 状態: **Accepted**
- 日付: 2026-09-28
- 関連: [R-09, R-10](../02-requirements.md)

## 背景
- tmux を前提に運用している（`ws` でプロジェクトごとのセッションを作る）。
- nvim の分割と tmux のペインという 2 つのレイヤーがあり、行き来の操作性が微妙。
- 実際に一番使っているのは `<leader>ac`（claudecode.nvim）で、**Claude はすでに Neovim の中で動いている**。tmux が担っているのは実質 `ws` のセッション維持だけだった。
- tmux を Neovim で置き換える方法として [wurli/servery.nvim](https://github.com/wurli/servery.nvim) がある。
  - 2026-09-22 公開、Neovim 0.12 以上が必須。ディレクトリごとに常駐の Neovim サーバーを立て、`:connect` で切り替える。
  - 端末アプリを閉じても Neovim を生かし続ける `:detach!` は、まだ 0.13 nightly にしかない。

## 選択肢
| 案 | 概要 |
|----|------|
| A. tmux 主体 | セッション・ペインは tmux、nvim はエディタに徹する。移動キーを統一する |
| B. Neovim 主体 | ターミナル・Claude もすべて nvim 内。tmux はセッションを保つためだけに使うか、廃止する |
| C. 併用を整理 | tmux = プロジェクト（セッション）単位、nvim = その中のすべて。役割の境界をはっきり決める |

## 決定
**B（Neovim 主体）。tmux は `ws` のセッションを保つだけの「見えない裏方」に縮小する。**

- 分割・移動・ターミナル・Claude はすべて Neovim の中で行う。tmux のペインは使わない。
  - `C-h/j/k/l` は Neovim のウィンドウ移動だけにし、vim-tmux-navigator は外した。
  - Claude のメインは claudecode.nvim。並走させる追加分は `:ClaudeNew` / `:ClaudeSessions`（`<leader>an` / `<leader>al`）で立てる。
- **タブ = 作業文脈（worktree）** とする。`:Worktrees` で worktree を新しいタブで開くと、そのタブにだけ `:tcd` が効く。タブラインとステータスラインに worktree 名が出る。
- tmux は `ws` のセッション（プロジェクトごとの色分け、端末を閉じても生き残る）だけを担当する。
- servery.nvim は実験的に同梱する（`<leader>qp` / `:Sv`）。成熟して `:detach!` が安定版に入ったら、tmux を外すかをこの ADR で見直す。

## 影響
- tmux のキー操作を覚える必要がほぼなくなる。覚えるのは Neovim のウィンドウ・タブ操作だけ。
- Neovim が落ちると中の Claude も止まる。tmux のセッションの中で Neovim を動かしているので、端末アプリを閉じただけなら生き残る。
