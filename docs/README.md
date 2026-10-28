# docs — nvim-config の設計と運用

迷ったら、目的にはDNA、現在の進め方には開発ループ、合否には検証仕様を使う。このディレクトリはNeovimの設定として自動実行されない。文書はSpec Hubから開き、エージェントも原本として読む。

## 現行運用の正本

| 文書 | 決めること |
|---|---|
| [00. DNA](00-dna.md) | この環境の目的と変わらない原則 |
| [01. 開発ループ](01-dev-loop.md) | 実行グラフ、役割、所有範囲、受け渡し、判断と再開 |
| [02. 要求仕様](02-requirements.md) | 要求IDと受け入れ条件 |
| [03. 構成](03-architecture.md) | 実装ファイル、読み込み、コマンドの対応 |
| [04. 検証](04-verification.md) | 検証コマンド、停止条件、合否、未確認範囲 |
| [05. 学習ロードマップ](05-learning-path.md) | 普段使うキーと操作 |
| [tasks](tasks.md) | 現在の状態、直近の検証、残りの作業 |

新しい機能の操作は05、運用は01、検証条件は04へ反映する。手順や停止条件の写しを研究資料へ増やさない。更新時は `make doc-links-check` でファイル参照とこの索引からの到達性を確認できる。見出しのanchorや外部サイトの有効性は別途確認する。

## 判断の履歴

ADRは採用時の理由を残す。現行の手順は上表を参照し、後続ADRが更新する範囲を区別する。

| ADR | 題 | 状態 |
|---|---|---|
| [0001](adr/0001-docs-as-dna.md) | DNAと仕様をdocsに置く | Accepted |
| [0002](adr/0002-terminal-and-image-protocol.md) | Ghosttyと画像表示を採用 | Accepted。端末更新方針は0005へ |
| [0003](adr/0003-multiplexer-strategy.md) | Neovimが分割、tmuxがセッション保持を担当 | Accepted |
| [0004](adr/0004-plugin-selection-2026.md) | 2026年9月のプラグイン選定 | Accepted |
| [0005](adr/0005-ghostty-1.4-and-workflow.md) | Ghostty 1.4と再現可能な環境更新 | Accepted |
| [0006](adr/0006-execution-graph.md) | 実行グラフ、役割と同じ版の証拠 | Accepted |

## 調査・教材

次の資料は調査時点の記録や説明用の例。現在の実装状況はtasks、運用は01で確認する。

| 資料 | 用途・時点 |
|---|---|
| [入門HTML](agent-engineering-beginner.html) | ハーネス・ループ・グラフを一つの例で理解する。2026-10-28作成 |
| [実務HTML](agent-engineering-practical.html) | 分岐・合流・差し戻し・状態・受け渡しを理解する。2026-10-28作成 |
| [調査と提案](research-2026-10-27-agent-engineering.md) | 出典、用語の区別、導入仮説と評価案。2026-10-27時点 |
| [PDEレビュー](review-2026-10-01.md) | 修正前の再現例と検証の限界。2026-10-01時点 |
