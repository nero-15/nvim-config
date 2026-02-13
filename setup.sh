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
# 3. Git リポジトリ初期化
# ──────────────────────────────────────
if [ ! -d "$SCRIPT_DIR/.git" ]; then
  echo "[git] リポジトリを初期化"
  cd "$SCRIPT_DIR"
  git init
  git add -A
  git commit -m "initial: Neovim config"
  echo ""
  echo "[git] GitHub に push する場合:"
  echo "  gh repo create dotfiles-nvim --private --source=. --push"
  echo "  または:"
  echo "  git remote add origin git@github.com:<YOUR_USER>/dotfiles-nvim.git"
  echo "  git push -u origin main"
fi

# ──────────────────────────────────────
# 4. 依存ツールの確認
# ──────────────────────────────────────
echo ""
echo "=== 依存ツール確認 ==="

check_cmd() {
  if command -v "$1" &>/dev/null; then
    echo "  ✓ $1 $(command $1 --version 2>/dev/null | head -1)"
  else
    echo "  ✗ $1 が見つかりません → $2"
  fi
}

check_cmd "nvim" "https://github.com/neovim/neovim/releases (v0.10+ 推奨)"
check_cmd "git" "https://git-scm.com/"
check_cmd "node" "https://nodejs.org/ (LSP に必要)"
check_cmd "rg" "brew install ripgrep / apt install ripgrep (telescope の grep に必要)"
check_cmd "fd" "brew install fd / apt install fd-find (telescope の file find を高速化)"
check_cmd "tmux" "brew install tmux / apt install tmux"
check_cmd "claude" "npm install -g @anthropic-ai/claude-code"

# ──────────────────────────────────────
# 5. Nerd Font の確認
# ──────────────────────────────────────
echo ""
echo "=== Nerd Font ==="
echo "  アイコン表示に Nerd Font が必要です"
echo "  未インストールなら: https://www.nerdfonts.com/"
echo "  おすすめ: JetBrainsMono Nerd Font / Hack Nerd Font"
echo "  ターミナルのフォント設定を Nerd Font に変更してください"

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
