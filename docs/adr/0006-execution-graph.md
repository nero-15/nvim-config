# ADR-0006: 開発ループを役割と受け渡し条件のある実行グラフにする

- 状態: **Accepted**
- 日付: 2026-10-28
- 関連: [R-04, R-05, R-06, R-07, R-09, R-13, R-21, R-22](../02-requirements.md)
- 継承: [DNA](../00-dna.md)、[ADR-0001](0001-docs-as-dna.md)、[ADR-0003](0003-multiplexer-strategy.md)
- 運用の正本: [01-dev-loop.md](../01-dev-loop.md)
- 検証の正本: [04-verification.md](../04-verification.md)

## 背景

この環境には要求ID、MakerとCheckerの分離、worktree、Verify、引き継ぎがある。一方、誰が共有ファイルを編集するか、統合後にどの版を確認するか、過去の提案と現行運用のどちらを読むかが文書間で曖昧だった。

sportscom-apiのコミット `a14fa731c` にある `docs/adr/0041-loop-as-execution-graph.md` と `docs/development/01-loop-engineering.md` を読み、役割・書き込み所有・同じ版の証拠・日常checkと全体verifyを分ける考え方を参考にした。業務固有の仕様、機能一覧、測定値、運用上限は移植しない。

Claude向けの定義は公式の [保存workflow](https://code.claude.com/docs/en/workflows#what-the-saved-script-looks-like)、[subagent frontmatter](https://code.claude.com/docs/en/sub-agents#frontmatter-reference)、[hookのexit 2](https://code.claude.com/docs/en/hooks#exit-code-2) に合わせる。実Runtimeでの動作確認は、ローカルのmock検査とは分けて記録する。

## 決定

1. 基本経路をPlanner → Maker → 独立Checker → 統括の公開とする。実装の差し戻し先はMaker。統合・競合解消もMakerの責任とし、Checkerは統合後の版を確認する。
2. 並列化の前に依存と書き込み所有を決める。共有の一覧・lock・コマンド登録・タスク記録には所有者を一人置く。小さな仕事まで多数の担当に分解しない。
3. 判定にHEAD SHAと未コミット変更の扱いを含める。SHAだけでdirtyな作業木の内容を保証しない。Checker後の変更は再検証する。
4. エディタに `:Check` / `<Space>vc` を設け、プロジェクトの `check` を明示的に呼ぶ。未定義なら通知し、Verifyへ暗黙に代用しない。nvim-configのcheckは既存の全verifyを実行し、短い検査を削減しない。
5. Claude CodeにはMaker/Checker定義と役割hook、再利用する読み取り監査には保存したworkflowを置く。hookを完全なsandboxとは扱わず、Codexへの自動適用も主張しない。
6. 現行運用は01、検証の内容と合否は04、操作は05へ集約する。研究とHTMLは時点付きの教材として維持し、現行文書へリンクする。進捗はtasks、過去の変更経緯はGitで保持する。

## nvim-configで維持する境界

この変更は [DNA](../00-dna.md) の「矛盾は止めて報告」「5反復ごとの人間チェックポイント」を置き換えない。ユーザーの既存承認内の通常作業は進め、仕様の矛盾は原本と根拠を示して報告する。Checkerからの投稿や統括のpush・mergeは、ユーザーが認めた範囲で行う。

Ghostty・tmux・Neovimの分担と中心プラグインは維持する。新しいグラフDBや独自エージェント実行基盤は導入しない。まず既存CLI、役割定義、検証コマンド、ファイルの記録を接続する。

## 検証と戻し方

検証条件は [04-verification.md](../04-verification.md) を参照する。役割hookの許可・拒否、Check/Verifyの選択、保存失敗、文書リンクも変更に応じて確認する。workflowの定義検査と実サービス上の実行確認は区別して報告する。

戻す場合は、この変更のコミットを確認して対象の設定・役割定義・hook・workflowと文書を一緒に戻す。ユーザーの既存設定や未コミット変更を巻き戻さない。検証条件を緩めて戻したことにはしない。
