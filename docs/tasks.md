# tasks — セッションをまたぐ引き継ぎ

エージェント・人間ともに、セッションの開始時に読み、終了時に更新する。

## Done
- 2026-09-27: `docs/` を新設。DNA・開発ループ・要求・構成・検証・学習・ADR を配置（ADR-0001）
- 2026-09-28: 特殊ディレクトリを新設（plugin, after/ftplugin, after/lsp, ftdetect, snippets, doc）。.gitignore で除外されていた lazy-lock.json と plugin/ を追跡対象に戻した
- 2026-09-28: Neovim 0.11.6 → 0.12.5
- 2026-09-28: Ghostty に移行、ws は呼び出し元の端末で開く（ADR-0002）
- 2026-09-28: 分割・Claude を Neovim に寄せ、tmux は裏方に（ADR-0003）
- 2026-09-28: プラグインを刷新（ADR-0004）。独自コマンド :Verify / :Spec / :Tasks / :Worktrees / :ClaudeNew / :Preview など
- 2026-09-28: `scripts/verify.sh`（V-1〜V-4, V-7）を追加。green（起動 24ms、スモーク 15/15）
- 2026-09-28: treesitter パーサー 30 種・LSP サーバー 14 種をインストール
- 2026-09-28: レッスン（lessons/00〜11, :Lesson）を追加。:Tutor を有効化、vim-be-good を追加

## In progress
- なし

## Next
- [ ] 1 週間使ってみて、馴染まないキーマップを見直す（`<Space>fH` で hardtime の集計を見る）
- [ ] Ghostty 上で Mermaid のインライン表示を目視で確認する（R-02。機械では判定できない）
- [ ] servery.nvim を試し、tmux を外せるか判断する（ADR-0003 の見直し条件: `:detach!` が安定版に入る）
- [ ] 2026-10 中旬: Terminal.app を 1 度も開かなかったら、`ws` の Terminal.app 分岐を残すか消すか決める（ADR-0002）
- [ ] snacks.nvim の更新状況を確認（2026-05 から止まっている。止まったままなら fzf-lua を検討。ADR-0004）

## 解決済みの環境問題（記録）
- 2026-09-28: Xcode.app の 27.0 への自動更新の途中で、古いリンカと新しい SDK が混ざり、C のビルド（treesitter パーサー）が `unknown architecture arm64e.x1` で失敗した。
  その後、新しいライセンスへの同意待ちで `/usr/bin/git` も止まった。`sudo xcodebuild -license accept` で解決し、回避策（DEVELOPER_DIR）は外した。
  - 同じ症状が出たら: Xcode の更新が終わっているか、ライセンスに同意したかを先に確認する。
