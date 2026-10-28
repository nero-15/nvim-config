# Neovim aliases (managed by dotfiles-nvim)
alias v="nvim"

# 電源接続中は claude が動いている間スリープさせない（caffeinate -s はバッテリー時は効かない。蓋を閉じたら止まる）
# Neovim の :terminal の中では TMUX を外す（tmux 用に包んだ OSC 52 が入力欄に漏れるため。lua/workflow/claude.lua）
claude() {
  local -a pre=()
  [[ -n "${NVIM:-}" ]] && pre=(env -u TMUX -u TMUX_PANE)
  command -v caffeinate &>/dev/null && pre+=(caffeinate -s)
  if (( ${#pre[@]} )); then "${pre[@]}" claude "$@"; else command claude "$@"; fi
}

# tmux ステータスバー色割り当て（プロジェクト名のハッシュから決定論的に選択）
_ws_color() {
  local colors=("#1e3a5f" "#1e4a2e" "#3a1e5f" "#1e4a4a" "#4a1e2e" "#4a3a1e" "#2e3a4a" "#4a1e4a")
  local hash=$(printf '%s' "$1" | cksum | awk '{print $1}')
  local offset=0
  [ -n "${ZSH_VERSION:-}" ] && offset=1
  printf '%s\n' "${colors[$((hash % 8 + offset))]}"
}

# shell と AppleScript は別々に引用する。パス内の引用符・改行もデータとして扱う。
_ws_shell_quote() {
  printf "'"
  printf '%s' "$1" | sed "s/'/'\\\\''/g"
  printf "'"
}

_ws_applescript_quote() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\t'/\\t}"
  printf '%s' "$value"
}

# 同名のプロジェクト/worktreeを区別。旧4桁hash/basenameは実行元が一致する場合だけ再利用。
_ws_session_name() {
  local dir="$1" label candidate existing digest legacy_base legacy_hash origin
  label=$(basename "$dir")
  if command -v shasum >/dev/null 2>&1; then
    digest=$(printf '%s' "$dir" | shasum -a 256 | cut -c1-12)
  elif command -v sha256sum >/dev/null 2>&1; then
    digest=$(printf '%s' "$dir" | sha256sum | cut -c1-12)
  else
    printf '%s\n' 'shasum または sha256sum が必要です' >&2
    return 1
  fi
  candidate="$(printf '%s' "$label" | LC_ALL=C tr -cs 'a-zA-Z0-9_-' '_' | cut -c1-32)-$digest"
  legacy_base=$(printf '%s' "$label" | tr '.:' '__')
  legacy_hash=$(printf '%s' "$dir" | cksum | awk '{printf "%04x", $1 % 65536}')
  # SHA側を優先。旧IDは名前だけを信用せず、作成時ディレクトリも確認する。
  for existing in "$candidate" "$legacy_base-$legacy_hash" "$legacy_base" "$label"; do
    if tmux has-session -t "=$existing" 2>/dev/null; then
      origin=$(tmux display-message -p -t "=$existing:" '#{session_path}' 2>/dev/null)
      origin=$(cd "$origin" 2>/dev/null && pwd -P) || origin=""
      if [ "$origin" = "$dir" ]; then
        printf '%s\n' "$existing"
        return
      elif [ "$existing" = "$candidate" ]; then
        printf '%s\n' "別ディレクトリのセッションIDと衝突しました: $candidate" >&2
        return 1
      fi
    fi
  done
  printf '%s\n' "$candidate"
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
  local session_name="$1" color="$2" label="${3:-$1}"
  local quoted_label=$(_ws_shell_quote "$label")
  local target=$(_ws_shell_quote "=$session_name:")
  printf '%s\n' "tmux set-option -t $target @ws_label $quoted_label && tmux set-option -t $target status-style 'bg=$color,fg=#c0caf5' && tmux set-option -t $target pane-active-border-style 'fg=$color' && tmux set-option -t $target pane-border-style 'fg=#3b4261'"
}

# 新しいウィンドウで実行するシェルコマンド（既存セッションなら attach、なければ作って nvim 起動）
_ws_attach_cmd() {
  local dir="$1" session_name="$2" style="$3"
  local quoted_dir=$(_ws_shell_quote "$dir") name=$(_ws_shell_quote "$session_name")
  local target=$(_ws_shell_quote "=$session_name:")
  local pane=$(_ws_shell_quote "=$session_name:")
  # tmux formatの特殊文字はエスケープ。表示名にはhashを出さない。
  local label=$(basename "$dir")
  label="${label//\#/##}"
  label=$(_ws_shell_quote "#[bold] $label #[nobold]")
  printf '%s\n' "cd $quoted_dir && if tmux has-session -t $target 2>/dev/null; then true; else tmux new-session -d -s $name -c $quoted_dir && tmux send-keys -t $pane 'nvim' Enter; fi && $style && tmux set-option -t $target status-left $label && tmux attach-session -t $target"
}

# Terminal.app の新しいウィンドウで実行（従来の挙動そのまま）
_ws_script_terminal() {
  local cmd=$(_ws_applescript_quote "$1")
  printf '%s\n' "
    tell application \"Terminal\"
      do script \"$cmd\"
      activate
    end tell
  "
}

# Ghostty の新しいウィンドウで実行（Ghostty 1.3+ の AppleScript を使う）
# 未起動なら起動時に開く最初のウィンドウに流し込む（ウィンドウが 2 枚開くのを防ぐ）
_ws_script_ghostty() {
  local cmd=$(_ws_applescript_quote "$1") dir=$(_ws_applescript_quote "$2")
  printf '%s\n' "
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
    printf '%s\n' "[dry-run] tmux: new-session -d -s '$session_name' -c '$dir'（未作成時）→ switch-client -t '=$session_name'"
    return
  fi
  if ! tmux has-session -t "=$session_name:" 2>/dev/null; then
    tmux new-session -d -s "$session_name" -c "$dir" || return
    tmux send-keys -t "=$session_name:" 'nvim' Enter || return
  fi
  tmux set-option -t "=$session_name:" status-style "bg=$color,fg=#c0caf5"
  tmux set-option -t "=$session_name:" pane-active-border-style "fg=$color"
  tmux set-option -t "=$session_name:" pane-border-style "fg=#3b4261"
  local label=$(basename "$dir")
  label="${label//\#/##}"
  tmux set-option -t "=$session_name:" @ws_label "$(basename "$dir")"
  tmux set-option -t "=$session_name:" status-left "#[bold] $label #[nobold]"
  tmux switch-client -t "=$session_name:"
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
  selected=$(cd "$selected" && pwd -P) || return

  if ! command -v tmux >/dev/null 2>&1; then
    printf '%s\n' 'tmux が必要です: brew install tmux' >&2
    return 1
  fi

  local session_name
  session_name=$(_ws_session_name "$selected") || return
  local color
  color=$(_ws_color "$selected")

  if [ -n "${TMUX:-}" ] && [ -n "${WS_SWITCH:-}" ]; then
    _ws_switch_in_tmux "$selected" "$session_name" "$color"
    return
  fi

  local terminal cmd script
  terminal=$(_ws_detect_terminal)
  cmd=$(_ws_attach_cmd "$selected" "$session_name" "$(_ws_style_cmd "$session_name" "$color" "$(basename "$selected")")")
  if [ "$terminal" = "ghostty" ]; then
    script=$(_ws_script_ghostty "$cmd" "$selected")
  else
    script=$(_ws_script_terminal "$cmd")
  fi

  if [ -n "${WS_DRY_RUN:-}" ]; then
    echo "[dry-run] terminal=$terminal"
    printf '%s\n' "$script"
    return
  fi
  osascript -e "$script"
}
