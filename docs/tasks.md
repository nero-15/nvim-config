# tasks — セッションをまたぐ引き継ぎ

エージェント・人間ともに、セッションの開始時に読み、終了時に更新する。

## Done
- 2026-10-28: Ghosttyと並走開発環境を担当分離で最適化（R-02/R-04/R-05/R-06/R-09/R-20/R-21/R-22、[ADR-0005](adr/0005-ghostty-1.4-and-workflow.md)）。実機GhosttyをHomebrew経由で1.3.1→1.4.0へ更新し、設定検証pass。圧縮等は1.4の既定値を活用。専用update/check、冪等なリンク作成、実lockを変えない管理対象plugin復元を実装。lazy.nvim自身のbootstrap/ローカルpluginは復元対象外。
- 2026-10-28: Verifyの保存失敗中止・実行元quickfix・分割ログ・root/HEAD/時刻/終了コードの記録を実装。検証スクリプトの無出力異常終了・計測欠落による誤greenを防ぎ、checkoutと一時state/cache/logを固定。HEADは未コミット内容を保証しないことを明記。Spec Hub/検索にHTML・mmdとCodex/Agentsスキルを追加、並行Mermaid出力を分離、Go lintのcmd解決を堅牢化。
- 2026-10-28: wsをパスのSHA256で識別し、shell/AppleScript引用を分離。既存basename/旧4桁cksumセッションは作成元一致時だけ再利用。push前にorigin/mainの3aed3daを取り込み、別環境のcaffeinate・Go依存・V-8・既存テストを維持。既存研究資料は独立コミットへ保存。
- 2026-10-28: 統合後の独立CheckerでV-1〜V-4・V-7・V-8 green（22.630ms、25/25）。which-keyは設定問題・overlap・duplicateなし。固定版復元とwsは一時Git/専用tmux socketで検証。通常sandboxのsocket制限を受け、許可された実行環境で全体を確認。実mmdc→PNG（784×162）変換・画像確認pass。Ghostty内のインライン描画、実Claudeの操作、全V-6は未確認。アプリ/既存Neovimは強制再起動せず、次回起動から反映。戻し方はADR-0005。
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
