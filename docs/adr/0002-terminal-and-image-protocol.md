# ADR-0002: ターミナルアプリと画像表示

- 状態: **Accepted**
- 日付: 2026-09-28
- 関連: [R-02](../02-requirements.md)

## 背景
Mermaid 図や画像をエディタ内でインライン表示するには、ターミナルが画像プロトコル（kitty graphics protocol など）に対応している必要がある。
現在使っている Terminal.app はどの画像プロトコルにも対応していない。

## 選択肢
| 案 | インライン図 | 移行コスト |
|----|-------------|-----------|
| A. Terminal.app のまま | ✗（ブラウザでプレビュー） | なし |
| B. Ghostty に移行 | ✓（tmux の passthrough 設定が必要） | `ws` の AppleScript を書き換え |
| C. WezTerm / kitty に移行 | ✓ | 同上 |

## 決定
**B. Ghostty に移行する。ただし Terminal.app はフォールバックとして使える状態を保つ。**

- メイン端末は Ghostty（1.3 系）。設定はリポジトリの `ghostty/config` を正とし、`setup.sh` が `~/.config/ghostty/config` にリンクする。
  - フォント Hack Nerd Font Mono 14 / テーマ `TokyoNight Night`（Neovim の tokyonight-night と揃える）/ `macos-option-as-alt = true`。
- 画像・Mermaid は snacks.nvim image（kitty graphics protocol）で Neovim 内にインライン表示する。
  - tmux を挟むため `tmux.conf` で `allow-passthrough on` と `update-environment` に `TERM` / `TERM_PROGRAM` を追加する。
  - Mermaid → 画像変換に mermaid-cli（`mmdc`）、画像変換に ImageMagick（`magick`）を使う。どちらも無い環境ではエラーにしない。
- **`ws` は呼び出し元の端末アプリで新しいウィンドウを開く。** Terminal.app から実行したときの挙動は従来と完全に同じ。
  - 判定順: `WS_TERMINAL=ghostty|terminal`（明示指定）→ tmux 内ならクライアントの TERM（`xterm-ghostty` か）→ `TERM_PROGRAM` → `__CFBundleIdentifier`。判定できなければ Terminal.app。
  - Ghostty は 1.3 の AppleScript（`new window with configuration`）で開く。
  - tmux 内から実行したときも従来どおり新しいウィンドウを開く。`WS_SWITCH=1` なら今のウィンドウで `switch-client` する。
  - `WS_DRY_RUN=1` で実行せずに生成コマンドを表示できる。

## 結果
- Terminal.app ではインライン画像は出ない（ブラウザプレビューにフォールバック）。`ws` 自体は壊れない。
- Ghostty の AppleScript 初回実行時に macOS の「オートメーション」許可ダイアログが出る。
- tmux の役割は ADR-0003 のとおり「プロジェクトごとのセッションを保つ裏方」に縮小する。
