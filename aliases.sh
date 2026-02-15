# Neovim aliases (managed by dotfiles-nvim)
alias v="nvim"

# ワークスペースセレクター
# ws → fzf でプロジェクト選択 → 新しい Terminal.app ウィンドウで tmux + nvim 起動
WORKSPACE_DIR="$HOME/devel/workspace"

ws() {
  if ! command -v fzf &>/dev/null; then
    echo "fzf が必要です: brew install fzf"
    return 1
  fi

  # .code-workspace ファイルからプロジェクトパスを収集
  local projects=()
  for f in "$WORKSPACE_DIR"/*.code-workspace; do
    [ -f "$f" ] || continue
    local path
    path=$(python3 -c "
import json, os, sys
with open('$f') as fh:
    d = json.load(fh)
for folder in d.get('folders', []):
    p = folder.get('path', '')
    if p.startswith('/'):
        print(p)
    else:
        print(os.path.normpath(os.path.join('$WORKSPACE_DIR', p)))
    break
" 2>/dev/null)
    [ -d "$path" ] && projects+=("$path")
  done

  if [ ${#projects[@]} -eq 0 ]; then
    echo "プロジェクトが見つかりません: $WORKSPACE_DIR"
    return 1
  fi

  local selected
  selected=$(printf '%s\n' "${projects[@]}" | sort -u | fzf --height=40% --reverse --prompt="workspace > " --with-nth=-1 --delimiter=/)

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
