# Neovim aliases (managed by dotfiles-nvim)
alias v="nvim"

# tmux ステータスバー色割り当て（プロジェクト名のハッシュから決定論的に選択）
_ws_color() {
  local colors=("#1e3a5f" "#1e4a2e" "#3a1e5f" "#1e4a4a" "#4a1e2e" "#4a3a1e" "#2e3a4a" "#4a1e4a")
  local hash=$(echo -n "$1" | cksum | awk '{print $1}')
  echo "${colors[$((hash % 8 + 1))]}"
}

# 呼び出し元の端末アプリを判定して ghostty / terminal を返す
# 優先順: WS_TERMINAL（明示指定）→ tmux クライアントの TERM → TERM_PROGRAM → __CFBundleIdentifier
# 判定できなければ terminal（従来どおり Terminal.app）
_ws_detect_terminal() {
  case "${WS_TERMINAL:-}" in
    ghostty|terminal) echo "$WS_TERMINAL"; return ;;
    "") ;;
    *) echo "WS_TERMINAL は ghostty か terminal を指定してください（自動判定します）: $WS_TERMINAL" >&2 ;;
  esac

  # tmux 内では TERM_PROGRAM=tmux になるので、いま接続しているクライアントの TERM で判定
  if [ -n "${TMUX:-}" ]; then
    local client_term
    client_term=$(tmux display-message -p '#{client_termname}' 2>/dev/null)
    [ "$client_term" = "xterm-ghostty" ] && echo ghostty || echo terminal
    return
  fi

  if [ "${TERM_PROGRAM:-}" = "ghostty" ] || [ "${__CFBundleIdentifier:-}" = "com.mitchellh.ghostty" ]; then
    echo ghostty
  else
    echo terminal
  fi
}

# セッションの色設定（tmux コマンド列）
_ws_style_cmd() {
  local session_name="$1" color="$2"
  local cmd="tmux set-option -t '=$session_name' status-style 'bg=$color,fg=#c0caf5'"
  cmd="$cmd; tmux set-option -t '=$session_name' pane-active-border-style 'fg=$color'"
  cmd="$cmd; tmux set-option -t '=$session_name' pane-border-style 'fg=#3b4261'"
  echo "$cmd"
}

# 新しいウィンドウで実行するシェルコマンド（既存セッションなら attach、なければ作って nvim 起動）
_ws_attach_cmd() {
  local dir="$1" session_name="$2" style="$3"
  echo "cd '$dir' && if tmux has-session -t '=$session_name' 2>/dev/null; then $style; tmux attach-session -t '=$session_name'; else tmux new-session -d -s '$session_name'; $style; tmux send-keys -t '$session_name' 'v' Enter; tmux attach-session -t '=$session_name'; fi"
}

# Terminal.app の新しいウィンドウで実行（従来の挙動そのまま）
_ws_script_terminal() {
  local cmd="$1"
  echo "
    tell application \"Terminal\"
      do script \"$cmd\"
      activate
    end tell
  "
}

# Ghostty の新しいウィンドウで実行（Ghostty 1.3+ の AppleScript を使う）
# 未起動なら起動時に開く最初のウィンドウに流し込む（ウィンドウが 2 枚開くのを防ぐ）
_ws_script_ghostty() {
  local cmd="$1" dir="$2"
  echo "
    if application \"Ghostty\" is running then
      tell application \"Ghostty\"
        new window with configuration {initial working directory:\"$dir\", initial input:\"$cmd\" & linefeed}
        activate
      end tell
    else
      tell application \"Ghostty\"
        activate
        repeat 50 times
          if (count of windows) > 0 then exit repeat
          delay 0.1
        end repeat
        set t to focused terminal of selected tab of front window
        input text \"$cmd\" to t
        send key \"enter\" to t
      end tell
    end if
  "
}

# tmux 内から呼ばれたとき: 新しいウィンドウは開かず、今のクライアントをセッションごと切り替える
_ws_switch_in_tmux() {
  local dir="$1" session_name="$2" color="$3"
  if [ -n "${WS_DRY_RUN:-}" ]; then
    echo "[dry-run] tmux: new-session -d -s '$session_name' -c '$dir'（未作成時）+ send-keys 'v' → 色設定 → switch-client -t '=$session_name'"
    return
  fi
  if ! tmux has-session -t "=$session_name" 2>/dev/null; then
    tmux new-session -d -s "$session_name" -c "$dir"
    tmux send-keys -t "$session_name" 'v' Enter
  fi
  tmux set-option -t "=$session_name" status-style "bg=$color,fg=#c0caf5"
  tmux set-option -t "=$session_name" pane-active-border-style "fg=$color"
  tmux set-option -t "=$session_name" pane-border-style "fg=#3b4261"
  tmux switch-client -t "=$session_name"
}

# ワークスペースセレクター
# ws [dir] → fzf でプロジェクト選択（dir 指定時は省略）→ 呼び出し元と同じ端末アプリの新しいウィンドウで tmux + nvim 起動
#   tmux 内で実行したときも従来どおり新しいウィンドウを開く（WS_SWITCH=1 なら今のウィンドウで switch-client）
#   WS_TERMINAL=ghostty|terminal で端末アプリを強制、WS_DRY_RUN=1 で実行せずにコマンドを表示
ws() {
  local selected="${1:-}"

  if [ -z "$selected" ]; then
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
      "$HOME/devel/spbl/repositories/spbl-ai-demo"
      "$HOME/devel/spbl/repositories/spbl-api"
      "$HOME/devel/spbl/repositories/spbl-infra"
      "$HOME/devel/spbl/repositories/spbl-web"
      "$HOME/devel/spbl/repositories/spbl-web-demo"
      "$HOME/devel/spbl-docker"
      "$HOME/devel/spbl-docker/server/www"
      "$HOME/devel/spbl-docker/server/cms"
    )

    selected=$(printf '%s\n' "${auto_projects[@]}" "${extra_projects[@]}" | sort -u | fzf --height=40% --reverse --prompt="workspace > " --with-nth=-1 --delimiter=/)
  fi

  [ -z "$selected" ] && return
  if [ ! -d "$selected" ]; then
    echo "ディレクトリがありません: $selected"
    return 1
  fi
  selected="${selected%/}"

  local session_name
  session_name=$(basename "$selected")
  local color
  color=$(_ws_color "$session_name")

  if [ -n "${TMUX:-}" ] && [ -n "${WS_SWITCH:-}" ]; then
    _ws_switch_in_tmux "$selected" "$session_name" "$color"
    return
  fi

  local terminal cmd script
  terminal=$(_ws_detect_terminal)
  cmd=$(_ws_attach_cmd "$selected" "$session_name" "$(_ws_style_cmd "$session_name" "$color")")
  if [ "$terminal" = "ghostty" ]; then
    script=$(_ws_script_ghostty "$cmd" "$selected")
  else
    script=$(_ws_script_terminal "$cmd")
  fi

  if [ -n "${WS_DRY_RUN:-}" ]; then
    echo "[dry-run] terminal=$terminal"
    echo "$script"
    return
  fi
  osascript -e "$script"
}
