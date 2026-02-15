# Neovim aliases (managed by dotfiles-nvim)
alias v="nvim"

# ワークスペースセレクター
# ws → fzf でプロジェクト選択 → 新しい Terminal.app ウィンドウで tmux + nvim 起動
ws() {
  if ! command -v fzf &>/dev/null; then
    echo "fzf が必要です: brew install fzf"
    return 1
  fi

  local projects=(
    "$HOME/devel/nvim-config"
    "$HOME/devel/Dawn-Editor"
    "$HOME/devel/anyteam-app"
    "$HOME/devel/anyteam"
    "$HOME/devel/charging-agentic-bulls"
    "$HOME/devel/kyushinkai-admin"
    "$HOME/devel/kyushinkai-api"
    "$HOME/devel/nero15.dev"
    "$HOME/devel/spbl"
    "$HOME/devel/spbl-app"
    "$HOME/devel/spbl/repositories/spbl-ai"
    "$HOME/devel/spbl/repositories/spbl-api"
    "$HOME/devel/spbl/repositories/spbl-infra"
    "$HOME/devel/spbl/repositories/spbl-web-demo"
  )

  local selected
  selected=$(printf '%s\n' "${projects[@]}" | fzf --height=40% --reverse --prompt="workspace > " --with-nth=-1 --delimiter=/)

  [ -z "$selected" ] && return

  local session_name
  session_name=$(basename "$selected")

  osascript -e "
    tell application \"Terminal\"
      do script \"cd '$selected' && tmux new-session -s '$session_name' \\\\; send-keys 'v .' Enter\"
      activate
    end tell
  "
}
