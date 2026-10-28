# ADR-0005: Ghostty 1.4 と再現可能な環境更新

- 状態: **Accepted**
- 日付: 2026-10-28
- 関連: [R-02, R-09, R-20, R-21, R-22](../02-requirements.md)
- 継承: [ADR-0002](0002-terminal-and-image-protocol.md)、[ADR-0003](0003-multiplexer-strategy.md)

## 背景

macOS 27.0.1 上で Ghostty 1.3.1 を使用していた。Ghostty 1.4 は macOS 27 の表示修正、
Kitty graphics の完全対応、履歴圧縮、端末処理の高速化、セキュリティ修正を含む。
本環境では Ghostty → tmux → Neovim → Claude Code と重なり、履歴を保持する場所も別である。
Ghostty の更新だけで tmux や Neovim、Claude のメモリまで圧縮されるわけではない。

また、従来の setup は親ディレクトリのない初期環境で Neovim のリンク作成が失敗し、
再実行時には既に正しいリンクまでバックアップしていた。
プラグイン導入の `:Lazy sync` は更新を伴い、固定された `lazy-lock.json` の再現にならなかった。

## 決定

1. **Ghostty 1.4 以上を推奨する。** 設定は1.3でも読める構文を維持し、1.4の既定の履歴圧縮と
   50 MB の履歴上限を利用する。無制限の履歴や根拠のないGPU/メモリ調整は加えない。
2. **分割はNeovim、セッション保持はtmuxを維持する。** 既存の画像passthroughとsnacks.imageを使う。
   Mermaidの描画結果は実画面で別途確認する。アニメーション対応はMermaidそのもののアニメ化ではない。
3. **Ghosttyの更新をsetupから明示的に実行できるようにする。**
   `bash setup.sh --upgrade-ghostty` はHomebrew管理のGhosttyだけを更新し、
   安定版1.4以上と設定の妥当性を検証する。手動導入.appを削除・置換せず、実行中アプリも終了しない。
   更新だけの呼び出しではシェル設定、リンク、プラグインを変更しない。
   `bash setup.sh --check-ghostty` は同じ検証だけを行う。
4. **リンク作成を共通化し、再実行を冪等にする。** 親ディレクトリを作り、正しいリンクは維持、
   既存ファイル/ディレクトリ/別リンクはバックアップしてから置き換える。
5. **通常setupでプラグインを更新しない。** 専用スクリプトは起動時の自動installを止め、
   lockの一時コピーで既存pluginをrestoreし、元の固定版を再読込して未導入pluginをinstallする。
   管理対象pluginのHEADを固定版と照合し、実lockが不変であることを確認する。取得やbuildの失敗は非zeroで止める。
   ローカルpluginとlazy.nvim自身のbootstrapはこの復元対象外である。
   新版を採用するときは別途 `:Lazy` で明示的に更新し、検証してlock差分をレビューする。

## 使い方と検証

```sh
bash setup.sh --upgrade-ghostty
bash setup.sh --check-ghostty
bash scripts/terminal-tests.sh
bash scripts/verify.sh
```

terminal-testsは一時ディレクトリ内のリンク、偽CLIによる版判定、ローカルGitリポジトリと実lazy.nvimに
よる「既存pluginの版ズレ＋未導入plugin」の復元、復元失敗の伝播、元lock不変を検証する。
ネットワークや稼働中のNeovim/tmuxには触れない。

SSHは必要な場面で `ghostty +ssh user@host` を明示的に使う。全SSHの挙動を変えるaliasは追加しない。
画像クリップボードの利用可否はアプリと中間層の対応にも依存するため、自動的な改善とは扱わない。

## 戻し方

- 設定変更は該当コミットをrevertし、Ghostty設定を再読み込みする。
- リンクを戻す場合はsetupが作った `.backup.<日時>.<PID>` を確認して復元する。
- Ghosttyアプリの更新はGitのrevertでは戻らない。旧版が必要な場合は公式配布版を別途導入する。
  1.3.1には今回修正された脆弱性があるため、安易なダウングレードは避ける。
- プラグインは採用するlockを戻して通常setupのプラグイン導入を実行する。

## 根拠

- [Ghostty 1.4.0 release notes](https://ghostty.org/docs/install/release-notes/1-4-0)
- [Homebrew upgrade](https://docs.brew.sh/Manpage#upgrade-options-installed_formulainstalled_cask-)
- [lazy.nvim lockfile](https://lazy.folke.io/usage/lockfile)
- 導入済みlazy.nvimの `manage/init.lua`、`manage/lock.lua`、`core/loader.lua` を確認。
  restoreは既存pluginのみを対象とし、install後のlock更新が混在状態に影響するため、一時lockを使用する。
