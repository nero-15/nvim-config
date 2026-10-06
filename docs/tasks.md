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
- 2026-10-06: 新しいマシンで setup.sh を実行。依存ツール・Ghostty・Nerd Font・プラグイン（lazy-lock どおりに restore）・パーサー 31 種・LSP 14 種を導入。go も追加で入れた（gopls 用）。verify green
- 2026-10-06: setup.sh をロックどおりに入れる `Lazy! restore` に変更し、依存チェックに go を追加（R-22）
- 2026-10-06: claude をシェル・claudecode.nvim・:ClaudeNew のどれから起動しても `caffeinate -s` 付きにした（電源接続中は動いている間スリープしない。R-09）
- 2026-10-06: Neovim 内の Claude でコピーすると入力欄に `52;c;<base64>` が出るバグを修正。原因は継承した `$TMUX` で Claude が OSC 52 を tmux 用 DCS に包み、Neovim の :terminal（libvterm）が解釈できずに表示していたこと。Neovim 内で起動する claude からは TMUX を外す（R-09）
- 2026-10-06: PDE レビューの issue #1〜#6 を修正。Verify の quickfix を実行元 root 基準に（#1）・分割出力を行に復元（#2）・setup.sh で親ディレクトリ作成とリンクの再実行対応（#3）・lazy-lock を restore で維持し更新手順を README に記載（#4）・Go lint を cmd で判定（#5）・ws のセッション名にパスのハッシュを付与（#6）。回帰テストを smoke（19 件）と verify.sh の V-8 に追加
- 2026-10-06: ws の色設定が tmux 3.7 で効いていなかった（`set-option -t '=name'` が no such session）。`=name:` に修正

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
