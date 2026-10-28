#!/bin/bash
# R-05/R-10: bash/zshで実行可。専用socketだけを操作し、GUI/実nvimは起動しない。
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
WS_TEST_REAL_TMUX=$(command -v tmux)
WS_TEST_DIR=$(mktemp -d /tmp/ws-regression.XXXXXX)
WS_TEST_SOCKET="$WS_TEST_DIR/socket"
export WS_TEST_REAL_TMUX WS_TEST_DIR WS_TEST_SOCKET
cleanup() {
  "$WS_TEST_REAL_TMUX" -S "$WS_TEST_SOCKET" kill-server 2>/dev/null || true
  rm -rf "$WS_TEST_DIR"
}
trap cleanup EXIT
mkdir -p "$WS_TEST_DIR/bin" "$WS_TEST_DIR/a/api" "$WS_TEST_DIR/b/api"
cat > "$WS_TEST_DIR/tmux.conf" <<'CONF'
set -g default-shell /bin/sh
set -g default-command 'exec sleep 60'
CONF
cat > "$WS_TEST_DIR/bin/tmux" <<'SH'
#!/bin/sh
case "$1" in
  attach-session|switch-client|send-keys)
    printf '%s\n' "$*" >> "$WS_TEST_DIR/actions"
    exit 0 ;;
esac
exec "$WS_TEST_REAL_TMUX" -S "$WS_TEST_SOCKET" -f "$WS_TEST_DIR/tmux.conf" "$@"
SH
chmod +x "$WS_TEST_DIR/bin/tmux"
PATH="$WS_TEST_DIR/bin:$PATH"
export PATH
. "$ROOT/aliases.sh"

a=$(cd "$WS_TEST_DIR/a/api" && pwd -P)
b=$(cd "$WS_TEST_DIR/b/api" && pwd -P)
a_id=$(_ws_session_name "$a")
b_id=$(_ws_session_name "$b")
[ "$a_id" != "$b_id" ]
tmux new-session -d -s api -c "$a"
[ "$(_ws_session_name "$a")" = api ]
[ "$(_ws_session_name "$b")" = "$b_id" ]
cmd=$(_ws_attach_cmd "$b" "$b_id" "$(_ws_style_cmd "$b_id" "$(_ws_color "$b")")")
/bin/sh -c "$cmd"
/bin/sh -c "$cmd"
[ "$(tmux display-message -p -t "=$b_id:" '#{session_path}')" = "$b" ]
[ "$(tmux display-message -p -t '=api:' '#{session_path}')" = "$a" ]
[ "$(tmux show-options -v -t "=$b_id:" status-left)" = '#[bold] api #[nobold]' ]
[ "$(grep -c '^send-keys ' "$WS_TEST_DIR/actions")" -eq 1 ]
ln -s "$b" "$WS_TEST_DIR/alias"
WS_DRY_RUN=1 WS_TERMINAL=ghostty ws "$WS_TEST_DIR/alias/" > "$WS_TEST_DIR/dry"
grep -F -- "$b_id" "$WS_TEST_DIR/dry" >/dev/null

# 二重の解釈(shell → AppleScript)でも引用符・backslash・$()を実行しない。
weird="$WS_TEST_DIR/quo'te\"\$(touch WS_INJECTED)\\tail"
mkdir -p "$weird"
weird=$(cd "$weird" && pwd -P)
weird_id=$(_ws_session_name "$weird")
cmd=$(_ws_attach_cmd "$weird" "$weird_id" "$(_ws_style_cmd "$weird_id" "$(_ws_color "$weird")")")
/bin/sh -c "$cmd"
[ "$(tmux display-message -p -t "=$weird_id:" '#{session_path}')" = "$weird" ]
[ ! -e "$weird/WS_INJECTED" ]
quoted=$(_ws_shell_quote "$weird")
[ "$(/bin/sh -c "printf '%s' $quoted")" = "$weird" ]
if command -v osascript >/dev/null 2>&1; then
  quoted=$(_ws_applescript_quote "$weird")
  [ "$(osascript -e "return \"$quoted\"")" = "$weird" ]
fi
WS_DRY_RUN=1 WS_TERMINAL=ghostty ws "$weird" > "$WS_TEST_DIR/ghostty-script"
WS_DRY_RUN=1 WS_TERMINAL=terminal ws "$weird" > "$WS_TEST_DIR/terminal-script"
# switch経路も同じセッションを使う。stubはクライアントを切り替えない。
TMUX=fixture WS_SWITCH=1 ws "$b"
grep -F -- "switch-client -t =$b_id:" "$WS_TEST_DIR/actions" >/dev/null
printf '%s\n' 'ws regression: duplicate names, legacy reuse, symlinks, shell/AppleScript quoting, attach/switch passed'
