# tasks — 現在の状態と次の一手

セッション開始時に読み、終了時に状態を更新する。運用は [01-dev-loop.md](01-dev-loop.md)、合否は [04-verification.md](04-verification.md) が正本。変更の詳細な経緯はGit履歴に残す。

## 現在

- Ghostty 1.4.0／macOS 27.0.1。Ghosttyは表示、tmuxはセッション保持、Neovimは分割・仕様閲覧・Claude操作を担当する。
- 実行元を固定したVerify、分割ログの復元、保存失敗時の中止、HEAD・時刻・終了コードの記録を導入済み。記録は未コミット内容の同一性を保証しない。
- Spec HubはMarkdown・HTML・Mermaidとエージェントの原本を探す入口。並行する同名Mermaidの変換先を分離し、Go lintの実行名判定を修正済み。
- setupは冪等なリンクとlockに基づくプラグイン復元を行う。Ghosttyの更新／検査は明示オプション。wsはパスのSHA256で識別し、旧basename／4桁cksumセッションは作成元一致時だけ再利用する。
- 別環境の変更を統合し、Claudeの `caffeinate -s`、Neovim内のTMUX除去、Go依存導入を維持している。[ADR-0005](adr/0005-ghostty-1.4-and-workflow.md)

## 作業中

- 2026-10-28: sportscom-api `a14fa731c` の実行グラフを参考に、役割・所有範囲・同じ版の検証をnvim-configへ適用する。[ADR-0006](adr/0006-execution-graph.md)
- `:Check`／`<Space>vc`、Claude CodeのMaker／Checker・役割hook・保存audit workflow、文書参照検査を実装・統合中。現在の版に対する最終検証と独立レビューは、この項目を完了へ移す前に記録する。
- 現行運用を01、検証を04へ集約し、研究・HTMLに作成時点と現行導線を追加。過去の報告を現在の未実装一覧として読ませない。

## 直近の検証済み状態

以下は**今回の実行グラフ変更前**、コミット `7e0e197` に記録された2026-10-28の結果。現在の作業中差分の合格を示さない。

- 独立Checker: V-1〜V-4・V-7・V-8 green、起動22.630ms、smoke 25/25。
- which-key: 設定問題・overlap・duplicateなし。
- lock復元とws: 一時Gitリポジトリ／専用tmux socketで検証。通常sandboxでsocketが作れないため、許可された環境で確認。
- 実mmdc→PNG変換と画像確認pass。Ghostty内のインライン描画、実Claude操作、V-6全体、教材HTMLの実ブラウザ描画は未確認。
- Ghosttyアプリと既存Neovimは強制再起動していない。新しい設定は作業の区切りで再起動して反映する。

## 残り

- [ ] 今回の統合版について必要な機械検証と独立レビューを完了し、対象版・結果・未確認範囲をここへ記録する。
- [ ] Ghostty上でMermaidのインライン表示、スクロール、サイズ変更を目視確認する（R-02）。
- [ ] 実Claudeの選択・コピーと会話再開を確認する（R-09）。
- [ ] 保存audit workflowは対応する実Runtimeで実行確認し、mock検査と区別して記録する。
- [ ] 新操作を一週間使った後、`<Space>fH` と実際の困りごとを基にキーを見直す。開始日を記録してから期間を数える。
- [ ] servery.nvimによるセッション保持が要件を満たすか確認し、tmuxを外す場合はADR-0003を更新する。
- [ ] Terminal.appフォールバックと中心プラグインの見直しは、実際の利用状況と保守状況を確認した時点で判断する。以前の期限や未確認の更新停止情報だけで削除・入替を決めない。

## 過去の記録・教材

- [2026-10-01 PDEレビュー](review-2026-10-01.md): 修正前の問題と再現条件。現在の未修正一覧ではない。
- [2026-10-27 調査と提案](research-2026-10-27-agent-engineering.md): ハーネス・ループ・グラフの調査時点の記録。
- [入門HTML](agent-engineering-beginner.html)／[実務HTML](agent-engineering-practical.html): 作成時点の例で学ぶ教材。
- 2026年9〜10月の導入・別環境での修正・統合の詳細は `git log -- docs/tasks.md` と `git show 7e0e197:docs/tasks.md` で参照する。同じ問題の別環境修正を、再発や二重導入と混同しない。
- Xcode更新中のSDK／リンカ不整合とライセンス待ちの復旧記録も、上記履歴に残る。再発時は更新完了とライセンス状態を先に確認する。
