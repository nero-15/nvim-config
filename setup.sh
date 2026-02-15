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
# 3. シェルエイリアスの登録
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
# 4. 依存ツールの自動インストール
# ──────────────────────────────────────
echo ""
echo "=== 依存ツール確認 ==="

MISSING_BREW=()
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
check_cmd "lazygit" "lazygit"   ""
check_cmd "claude"  ""          "npm install -g @anthropic-ai/claude-code"

# brew で一括インストール
if [ ${#MISSING_BREW[@]} -gt 0 ] && command -v brew &>/dev/null; then
  echo ""
  echo "  未インストール: ${MISSING_BREW[*]}"
  read -rp "  brew install で一括インストールしますか？ [y/N] " yn
  if [[ "$yn" =~ ^[Yy]$ ]]; then
    brew install "${MISSING_BREW[@]}"
  fi
elif [ ${#MISSING_BREW[@]} -gt 0 ]; then
  echo ""
  echo "  brew が見つかりません。以下を手動でインストールしてください:"
  for pkg in "${MISSING_BREW[@]}"; do
    echo "    - $pkg"
  done
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
# 5. Nerd Font のインストール
# ──────────────────────────────────────
echo ""
echo "=== Nerd Font ==="
NERD_FONT_INSTALLED=false
if fc-list 2>/dev/null | grep -qi "Nerd" || system_profiler SPFontsDataType 2>/dev/null | grep -qi "Nerd"; then
  echo "  ✓ Nerd Font インストール済み"
  NERD_FONT_INSTALLED=true
else
  echo "  ✗ Nerd Font が見つかりません（アイコン表示に必要）"
  if command -v brew &>/dev/null; then
    read -rp "  Hack Nerd Font をインストールしますか？ [y/N] " yn
    if [[ "$yn" =~ ^[Yy]$ ]]; then
      brew install --cask font-hack-nerd-font
      NERD_FONT_INSTALLED=true
    fi
  else
    echo "  手動インストール: https://www.nerdfonts.com/"
  fi
fi

if [ "$NERD_FONT_INSTALLED" = true ]; then
  echo "  ※ ターミナルのフォント設定を Nerd Font に変更してください"
  echo "    Terminal.app: 設定 → プロファイル → テキスト → フォント → Hack Nerd Font Mono"
fi

# ──────────────────────────────────────
# 完了
# ──────────────────────────────────────
echo ""
echo "=== セットアップ完了 ==="
echo ""
echo "次のステップ:"
echo "  1. nvim を起動 (初回は lazy.nvim がプラグインを自動インストール)"
echo "  2. :Mason で LSP サーバーの状態を確認"
echo "  3. :checkhealth で環境の診断"
echo ""
echo "最速への道が始まる。"
