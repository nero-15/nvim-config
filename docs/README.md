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
| — | [エージェント環境の調査と提案（2026-10-27）](research-2026-10-27-agent-engineering.md) | ハーネス・ループ・グラフ、共有記事の検証、個人環境から始める導入案 |
| — | [はじめてのハーネス・ループ・グラフ（HTML）](agent-engineering-beginner.html) | 一つの調査資料作成例で読む、図解付きの入門資料 |
| — | [グラフで、AIの仕事をどう設計するか（HTML）](agent-engineering-practical.html) | 入門と詳細調査の中間。最近の動向、状態・受け渡し・検証・再開を実際の開発例で説明 |

## ADR 一覧

| # | 題 | 状態 |
|---|----|------|
| [0001](adr/0001-docs-as-dna.md) | DNA と仕様を docs/ に置き、設定もループで育てる | Accepted |
| [0002](adr/0002-terminal-and-image-protocol.md) | ターミナルアプリと画像表示（Ghostty） | Accepted |
| [0003](adr/0003-multiplexer-strategy.md) | 画面分割のレイヤーを Neovim に寄せ、tmux は裏方に | Accepted |
| [0004](adr/0004-plugin-selection-2026.md) | 2026 年 9 月時点のプラグイン選定 | Accepted |
| [0005](adr/0005-ghostty-1.4-and-workflow.md) | Ghostty 1.4と再現可能なエージェント開発環境 | Accepted |
