# docs — nvim-config の設計書

この環境の DNA・要求・判断の記録。**Neovim はこのディレクトリを読み込まない**（動作には影響しない）。

## 読む順番

| # | 文書 | 内容 |
|---|------|------|
| 00 | [DNA](00-dna.md) | 大前提。AI 駆動・仕様駆動・ループエンジニアリング。**迷ったらここ** |
| 01 | [開発ループ](01-dev-loop.md) | 実際の運用と、その中でエディタが担う役割 |
| 02 | [要求仕様](02-requirements.md) | `R-xx` で管理する要求と受け入れ条件 |
| 03 | [構成](03-architecture.md) | ファイル構成と読み込みの流れ |
| 04 | [検証](04-verification.md) | 変更が完了したと言える停止条件 |
| 05 | [学習ロードマップ](05-learning-path.md) | Vim を学び直す道筋 |
| — | [ADR](adr/) | 採用・不採用の判断の記録 |
| — | [tasks](tasks.md) | セッションをまたぐ引き継ぎ（外部メモリ） |

## ADR 一覧

| # | 題 | 状態 |
|---|----|------|
| [0001](adr/0001-docs-as-dna.md) | DNA と仕様を docs/ に置き、設定もループで育てる | Accepted |
| [0002](adr/0002-terminal-and-image-protocol.md) | ターミナルアプリと画像表示（Ghostty） | Accepted |
| [0003](adr/0003-multiplexer-strategy.md) | 画面分割のレイヤーを Neovim に寄せ、tmux は裏方に | Accepted |
| [0004](adr/0004-plugin-selection-2026.md) | 2026 年 9 月時点のプラグイン選定 | Accepted |
