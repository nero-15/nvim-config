# AGENTS.md — nvim-config

このリポジトリでエージェント（および人間）が守る最小ルール。詳細は [CLAUDE.md](CLAUDE.md) と [docs/](docs/README.md)。

## まず読む
- [docs/00-dna.md](docs/00-dna.md) — この環境が存在する理由
- [docs/02-requirements.md](docs/02-requirements.md) — 要求と受け入れ条件
- [docs/tasks.md](docs/tasks.md) — 前回までの進捗
- [docs/01-dev-loop.md](docs/01-dev-loop.md) — 実行グラフ・役割・作業パケット・同じ版の確認
- 文書の置き場所は [docs/README.md](docs/README.md) の「書く場所」の表で決める

## 黄金律
1. **エディタは「読む・判断する」ための道具。** 仕様（md / Mermaid / HTML）の可読性を最優先する。
2. **入れた機能は辿れるようにする。** which-key と [05-learning-path.md](docs/05-learning-path.md) に載せる。
3. **壊れない。** 外部ツールが欠けても起動エラーを出さない。
4. **理由を残す。** プラグインの入れ替えは ADR に書く。

## 停止条件（machine-judged）
`make check` が green（[docs/04-verification.md](docs/04-verification.md) の V-1〜V-4・V-7〜V-10）。
完了の報告には、出力末尾の `tree:` 行（検証した作業木の内容のID）を添える。版の照合は `make tree-id`。
作った担当と別のCheckerが同じtree IDを確認し、統合後に変更したら再検証する。

## 実行グラフ
- Planner → Maker（衝突解消も担当）→ 編集しないChecker → 統括の公開。差し戻しはMakerへ。
- 並列化は依存する出力と書き込み先が重ならない場合だけ。共有ファイルは担当を一人に決める。
- Claude用の役割定義と保存auditは `.claude/`、Codexでの権限・委任は実際のツール設定に従う。ClaudeのhookがCodexにも効くと仮定しない。
- Checkerの結果は対象SHA・実行した検査・未確認範囲とともに統括へ返す。外部コメント送信はユーザーが明示した場合のみ。

## やってはいけない
- ユーザーの `~/.zshrc` や `~/.tmux.conf` を、`setup.sh` を経由せずに直接書き換える。
- ADR を書かずに、中心的なプラグイン（ピッカー、補完、LSP 周り）を入れ替える。
- 自分が書いた設定を、`make check` を実行せずに「完了」と報告する（Maker ≠ Checker）。
