# Neovim aliases (managed by dotfiles-nvim)
alias v="nvim"

# ワークスペースセレクター
# ws → fzf でプロジェクト選択 → 新しい Terminal.app ウィンドウで tmux + nvim 起動
ws() {
  if ! command -v fzf &>/dev/null; then
    echo "fzf が必要です: brew install fzf"
    return 1
  fi

  # ~/devel 直下のディレクトリを自動検出
  local auto_projects=()
  for d in "$HOME"/devel/*/; do
    [ -d "$d" ] && auto_projects+=("${d%/}")
  done

  # 階層が深いプロジェクトは直接登録
  local extra_projects=(
    "$HOME/devel/spbl/repositories/spbl-ai"
    "$HOME/devel/spbl/repositories/spbl-api"
    "$HOME/devel/spbl/repositories/spbl-infra"
    "$HOME/devel/spbl/repositories/spbl-web-demo"
  )

  local selected
  selected=$(printf '%s\n' "${auto_projects[@]}" "${extra_projects[@]}" | sort -u | fzf --height=40% --reverse --prompt="workspace > " --with-nth=-1 --delimiter=/)

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
