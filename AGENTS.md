# AGENTS.md — nvim-config

このリポジトリでエージェント（および人間）が守る最小ルール。詳細は [CLAUDE.md](CLAUDE.md) と [docs/](docs/README.md)。

## まず読む
- [docs/00-dna.md](docs/00-dna.md) — この環境が存在する理由
- [docs/02-requirements.md](docs/02-requirements.md) — 要求と受け入れ条件
- [docs/tasks.md](docs/tasks.md) — 前回までの進捗

## 黄金律
1. **エディタは「読む・判断する」ための道具。** 仕様（md / Mermaid / HTML）の可読性を最優先する。
2. **入れた機能は辿れるようにする。** which-key と [05-learning-path.md](docs/05-learning-path.md) に載せる。
3. **壊れない。** 外部ツールが欠けても起動エラーを出さない。
4. **理由を残す。** プラグインの入れ替えは ADR に書く。

## 停止条件（machine-judged）
[docs/04-verification.md](docs/04-verification.md) の V-1〜V-3 がすべて green。

## やってはいけない
- ユーザーの `~/.zshrc` や `~/.tmux.conf` を、`setup.sh` を経由せずに直接書き換える。
- ADR を書かずに、中心的なプラグイン（ピッカー、補完、LSP 周り）を入れ替える。
- 自分が書いた設定を、V-1〜V-3 を実行せずに「完了」と報告する（Maker ≠ Checker）。
