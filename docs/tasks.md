# tasks — セッションをまたぐ引き継ぎ

エージェント・人間ともに、セッションの開始時に読み、終了時に更新する。

## Done
- 2026-10-28: [グラフ設計の実務版HTML](agent-engineering-practical.html)を追加。入門版と詳細調査の中間の粒度で、最近の動向、ノード・エッジ・状態、過去の不具合を題材にした分岐・合流・差し戻し、同じ版の証拠と再開、個人環境への導入順を説明。主要3資料を再確認し、独立内容レビューで重大指摘なし。HTML構造・ID・内部リンクを確認。設定変更なし。既定検証V-1〜V-4・V-7 green（22.930ms、17/17）。ブラウザの実描画は未確認。
- 2026-10-28: [初学者向けHTML資料](agent-engineering-beginner.html)を追加。AIツール比較資料を作る一つの例で、モデル／エージェント、ハーネス、ループ、グラフを順に説明。静的な図解、個人環境での始め方、依頼文、用語集、印刷用表示を用意。独立レビューの2点を修正し、HTML構造・リンクを確認。設定変更なし。既定検証V-1〜V-4・V-7 green（25.213ms、17/17）。ブラウザの実描画は未確認。
- 2026-10-27: ハーネス・ループ・グラフ設計を主担当＋調査担当3人で調査。[調査報告](research-2026-10-27-agent-engineering.md)に共有されたSNS記事の検証、個人環境の既存手順との対応、2週間の試行案とチーム展開条件を記録。Dynamic workflows／Managed Agents／Dreamsを区別し、検証・再開・証拠の接続を優先する提案。設定変更、機能導入、ワークフロー実行、効果測定は未実施。独立文書レビューで重大指摘なし。state/cache/logを一時領域へ分離した既定検証はV-1〜V-4・V-7 green（24.213ms、17/17）。
- 2026-10-02: Claude の選択時に Base64 が端末表示へ漏れる経路を修正（R-09）。Claude 2.1.287 の通常 OSC 52 + tmux 用 DCS 出力を Neovim 内蔵端末で再現。メイン・追加の起動コマンドを共通化し、Claude 子プロセスだけ `TMUX` / `TMUX_PANE` を除去。回帰テストは修正前 red → 修正後 green、V-1〜V-4・V-7 green（59.466ms、17/17）。state/cache/log は一時領域に分離。起動済み Claude の再起動・ユーザー実画面での選択確認は未実施。会話再開と一時回避の手順は学習ガイドに記載。
- 2026-10-01: PDE レビューの6件を GitHub Issue [#1](https://github.com/nero-15/nvim-config/issues/1)〜[#6](https://github.com/nero-15/nvim-config/issues/6) に登録。各 Issue に再現条件・修正方針・受け入れ条件を記載。
- 2026-10-01: 現行 PDE をレビュー。[レビュー記録](review-2026-10-01.md) に6件の改修候補と再現結果を記載。設定改修は未実施。state/cache を一時領域に分離した検証で V-1〜V-4・V-7 green（23.591ms、16/16）、V-5 も問題なし。
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
