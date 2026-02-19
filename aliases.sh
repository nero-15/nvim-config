# Neovim aliases (managed by dotfiles-nvim)
alias v="nvim"

# tmux ステータスバー色割り当て（プロジェクト名のハッシュから決定論的に選択）
_ws_color() {
  local colors=("#1e3a5f" "#1e4a2e" "#3a1e5f" "#1e4a4a" "#4a1e2e" "#4a3a1e" "#2e3a4a" "#4a1e4a")
  local hash=$(echo -n "$1" | cksum | awk '{print $1}')
  echo "${colors[$((hash % 8 + 1))]}"
}

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
    "$HOME/devel"
    "$HOME/devel/spbl/repositories/spbl-ai"
    "$HOME/devel/spbl/repositories/spbl-api"
    "$HOME/devel/spbl/repositories/spbl-infra"
    "$HOME/devel/spbl/repositories/spbl-web-demo"
    "$HOME/devel/spbl-docker"
    "$HOME/devel/spbl-docker/server/www"
    "$HOME/devel/spbl-docker/server/cms"
  )

  local selected
  selected=$(printf '%s\n' "${auto_projects[@]}" "${extra_projects[@]}" | sort -u | fzf --height=40% --reverse --prompt="workspace > " --with-nth=-1 --delimiter=/)

  [ -z "$selected" ] && return

  local session_name
  session_name=$(basename "$selected")
  local color
  color=$(_ws_color "$session_name")

  # tmux セッションのスタイル設定
  local tmux_style
  tmux_style="tmux set-option -t '$session_name' status-style 'bg=$color,fg=#c0caf5'"
  tmux_style="$tmux_style; tmux set-option -t '$session_name' pane-active-border-style 'fg=$color'"
  tmux_style="$tmux_style; tmux set-option -t '$session_name' pane-border-style 'fg=#3b4261'"

  osascript -e "
    tell application \"Terminal\"
      do script \"cd '$selected' && if tmux has-session -t '$session_name' 2>/dev/null; then $tmux_style; tmux attach-session -t '$session_name'; else tmux new-session -d -s '$session_name'; $tmux_style; tmux send-keys -t '$session_name' 'v .' Enter; tmux attach-session -t '$session_name'; fi\"
      activate
    end tell
  "
}
