#!/bin/bash
# ==========================================================
# Neovim dotfiles セットアップスクリプト
# 実行: bash setup.sh
# ==========================================================

set -euo pipefail

NVIM_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Neovim dotfiles setup ==="
echo ""

# ──────────────────────────────────────
# 1. 既存設定のバックアップ
# ──────────────────────────────────────
if [ -d "$NVIM_CONFIG_DIR" ] || [ -L "$NVIM_CONFIG_DIR" ]; then
  BACKUP_DIR="${NVIM_CONFIG_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
  echo "[backup] 既存の設定を $BACKUP_DIR にバックアップ"
  mv "$NVIM_CONFIG_DIR" "$BACKUP_DIR"
fi

# ──────────────────────────────────────
# 2. シンボリックリンク作成
# ──────────────────────────────────────
echo "[link] $SCRIPT_DIR → $NVIM_CONFIG_DIR"
ln -sf "$SCRIPT_DIR" "$NVIM_CONFIG_DIR"

# ──────────────────────────────────────
# 3. tmux / Ghostty 設定のシンボリックリンク
# ──────────────────────────────────────
# 既存ファイルがあればバックアップしてからリンクを張る（リンク済みならスキップ）
link_config() {
  local label="$1" src="$2" dest="$3"

  mkdir -p "$(dirname "$dest")"
  if [ -f "$dest" ] || [ -L "$dest" ]; then
    if [ "$(readlink "$dest" 2>/dev/null)" = "$src" ]; then
      echo "[$label] $dest はリンク済み (スキップ)"
      return
    fi
    local backup
    backup="${dest}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "[$label] 既存の $dest を $backup にバックアップ"
    mv "$dest" "$backup"
  fi
  ln -sf "$src" "$dest"
  echo "[$label] $src → $dest"
}

link_config "tmux" "$SCRIPT_DIR/tmux.conf" "$HOME/.tmux.conf"
link_config "ghostty" "$SCRIPT_DIR/ghostty/config" "${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config"

# ──────────────────────────────────────
# 4. シェルエイリアスの登録
# ──────────────────────────────────────
ALIASES_SH="$SCRIPT_DIR/aliases.sh"
SOURCE_LINE="source \"$ALIASES_SH\""

# ログインシェルに応じたrcファイルを選択
case "${SHELL:-}" in
  */zsh)  RC_FILE="$HOME/.zshrc" ;;
  */bash) RC_FILE="$HOME/.bashrc" ;;
  *)      RC_FILE="$HOME/.zshrc" ;;
esac

if [ -f "$RC_FILE" ] && grep -qF "$ALIASES_SH" "$RC_FILE"; then
  echo "[alias] $RC_FILE に登録済み (スキップ)"
else
  echo "" >> "$RC_FILE"
  echo "# Neovim aliases (added by dotfiles-nvim setup)" >> "$RC_FILE"
  echo "$SOURCE_LINE" >> "$RC_FILE"
  echo "[alias] $RC_FILE に追記: $SOURCE_LINE"
fi

# ──────────────────────────────────────
# 5. 依存ツールの自動インストール
# ──────────────────────────────────────
echo ""
echo "=== 依存ツール確認 ==="

MISSING_BREW=()
MISSING_CASK=()
MISSING_MANUAL=()

check_cmd() {
  local cmd="$1"
  local brew_pkg="$2"
  local manual_hint="$3"

  if command -v "$cmd" &>/dev/null; then
    echo "  ✓ $cmd"
  else
    echo "  ✗ $cmd が見つかりません"
    if [ -n "$brew_pkg" ]; then
      MISSING_BREW+=("$brew_pkg")
    else
      MISSING_MANUAL+=("$cmd: $manual_hint")
    fi
  fi
}

check_cmd "nvim"    "neovim"    ""
check_cmd "git"     "git"       ""
check_cmd "node"    "node"      ""
check_cmd "rg"      "ripgrep"   ""
check_cmd "fd"      "fd"        ""
check_cmd "tmux"    "tmux"      ""
check_cmd "fzf"           "fzf"             ""
check_cmd "tree-sitter"   "tree-sitter-cli" ""
check_cmd "claude"        ""                "npm install -g @anthropic-ai/claude-code"
check_cmd "gh"            "gh"              ""
check_cmd "lazygit"       "lazygit"         ""
check_cmd "magick"        "imagemagick"     ""
check_cmd "mmdc"          ""                "npm install -g @mermaid-js/mermaid-cli"

# GUI アプリ（cask）は .app の有無で判定する
check_app() {
  local app="$1"
  local cask="$2"

  if [ -d "/Applications/$app.app" ] || [ -d "$HOME/Applications/$app.app" ]; then
    echo "  ✓ $app.app"
  else
    echo "  ✗ $app.app が見つかりません"
    MISSING_CASK+=("$cask")
  fi
}

check_app "Ghostty" "ghostty"

# brew で一括インストール
if [ ${#MISSING_BREW[@]} -gt 0 ] && command -v brew &>/dev/null; then
  echo ""
  echo "  未インストール: ${MISSING_BREW[*]}"
  read -rp "  brew install で一括インストールしますか？ [y/N] " yn || yn=""
  if [[ "$yn" =~ ^[Yy]$ ]]; then
    brew install "${MISSING_BREW[@]}" || echo "  [warn] brew install に失敗しました"
  fi
elif [ ${#MISSING_BREW[@]} -gt 0 ]; then
  echo ""
  echo "  brew が見つかりません。以下を手動でインストールしてください:"
  for pkg in "${MISSING_BREW[@]}"; do
    echo "    - $pkg"
  done
fi

# cask（GUI アプリ）を一括インストール
if [ ${#MISSING_CASK[@]} -gt 0 ] && command -v brew &>/dev/null; then
  echo ""
  echo "  未インストール (cask): ${MISSING_CASK[*]}"
  read -rp "  brew install --cask で一括インストールしますか？ [y/N] " yn || yn=""
  if [[ "$yn" =~ ^[Yy]$ ]]; then
    brew install --cask "${MISSING_CASK[@]}" || echo "  [warn] brew install --cask に失敗しました"
  fi
fi

# 手動インストールが必要なもの
if [ ${#MISSING_MANUAL[@]} -gt 0 ]; then
  echo ""
  echo "  以下は手動インストールが必要です:"
  for item in "${MISSING_MANUAL[@]}"; do
    echo "    - $item"
  done
fi

# ──────────────────────────────────────
# 6. Nerd Font のインストール
# ──────────────────────────────────────
echo ""
echo "=== Nerd Font ==="
NERD_FONT_INSTALLED=false
# pipefail 下で `cmd | grep -q` は SIGPIPE で偽陰性になり得るため、出力を変数に取ってから判定する
has_nerd_font() {
  grep -qi "Nerd" <<<"$(fc-list 2>/dev/null || true)" \
    || grep -qi "Nerd" <<<"$(system_profiler SPFontsDataType 2>/dev/null || true)"
}
if has_nerd_font; then
  echo "  ✓ Nerd Font インストール済み"
  NERD_FONT_INSTALLED=true
else
  echo "  ✗ Nerd Font が見つかりません（アイコン表示に必要）"
  if command -v brew &>/dev/null; then
    read -rp "  Hack Nerd Font をインストールしますか？ [y/N] " yn || yn=""
    if [[ "$yn" =~ ^[Yy]$ ]]; then
      if brew install --cask font-hack-nerd-font; then
        NERD_FONT_INSTALLED=true
      fi
    fi
  else
    echo "  手動インストール: https://www.nerdfonts.com/"
  fi
fi

# Terminal.app から実行したときだけフォントを変更する（Ghostty は ghostty/config で指定済み）
if [ "$NERD_FONT_INSTALLED" = true ] && [[ "${TERM_PROGRAM:-}" == "Apple_Terminal" ]]; then
  read -rp "  Terminal.app のフォントを Hack Nerd Font Mono に変更しますか？ [y/N] " yn || yn=""
  if [[ "$yn" =~ ^[Yy]$ ]]; then
    if osascript <<'APPLESCRIPT'
tell application "Terminal"
  set targetProfile to name of default settings
  set font name of settings set targetProfile to "HackNerdFontMono-Regular"
  set font size of settings set targetProfile to 14
end tell
APPLESCRIPT
    then
      echo "  [font] Terminal.app のフォントを変更しました"
    else
      echo "  [warn] Terminal.app のフォント変更に失敗しました"
    fi
  fi
fi

# ──────────────────────────────────────
# 7. プラグイン・パーサーの自動インストール
# ──────────────────────────────────────
echo ""
echo "=== プラグイン・パーサーのインストール ==="

if command -v nvim &>/dev/null; then
  read -rp "  nvim のプラグインと treesitter パーサーをインストールしますか？ [y/N] " yn || yn=""
  if [[ "$yn" =~ ^[Yy]$ ]]; then
    echo "  [plugin] lazy.nvim プラグインをインストール中..."
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || echo "  [warn] Lazy sync に失敗しました（nvim 内で :Lazy を確認）"
    echo "  [treesitter] パーサーをインストール中..."
    # nvim-treesitter (main) は install():wait() で同期インストール。一覧は lua/config/parsers.lua
    nvim --headless -c "lua require('nvim-treesitter').install(require('config.parsers')):wait(600000)" +qa 2>/dev/null \
      || echo "  [warn] パーサーのインストールに失敗しました（nvim 内で :TSInstall を確認）"
    echo "  [done] インストール完了"
  fi
fi

# ──────────────────────────────────────
# 完了
# ──────────────────────────────────────
echo ""
echo "=== セットアップ完了 ==="
echo ""
echo "次のステップ:"
echo "  1. nvim を起動"
echo "  2. :Mason で LSP サーバーの状態を確認"
echo "  3. :checkhealth で環境の診断"
echo ""
echo "最速への道が始まる。"
