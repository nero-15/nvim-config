#!/bin/sh
# ==========================================================
# agent-signal: Claude Code の hook → 親 Neovim へ状態を知らせる (R-14)
#   scripts/claude-hooks.json から `sh agent-signal.sh <イベント名>` で呼ばれる。
#   Neovim の :terminal で起動した Claude だけが対象 ($NVIM と $NVIM_CLAUDE_SLOT がある)。
# 何が起きても Claude を止めない: 出力なし・常に exit 0。
# ==========================================================
event=${1:-}
slot=${NVIM_CLAUDE_SLOT:-}
if [ -z "${NVIM:-}" ] || [ -z "$slot" ] || [ -z "$event" ]; then cat >/dev/null 2>&1; exit 0; fi
case "$slot$event" in *[!A-Za-z0-9_-]*) cat >/dev/null 2>&1; exit 0 ;; esac

# 「次のツール実行で作業中へ戻す」目印。判断待ち (Notification) と応答完了 (Stop) のあとに置く。
# 作業中の間は目印が無いので、ツール実行ごと (PostToolUse) に Neovim を起こさない。
# Stop のあとにも置くのは、Stop hook に促されて作業を続けた場合に「完了」のまま残さないため。
dir=${NVIM_AGENT_DIR:-}
marker="$dir/$slot.waiting"
mark() { [ -n "$dir" ] && mkdir -p "$dir" 2>/dev/null && : > "$marker" 2>/dev/null; }
unmark() { [ -n "$dir" ] && rm -f "$marker" 2>/dev/null; }
case "$event" in
  PostToolUse)
    cat >/dev/null 2>&1
    if [ -n "$dir" ] && [ ! -e "$marker" ]; then exit 0; fi
    unmark
    payload=""
    ;;
  Notification|Stop)
    payload=$(head -c 60000 2>/dev/null)
    mark
    ;;
  *)
    payload=$(head -c 60000 2>/dev/null)
    unmark
    ;;
esac

command -v nvim >/dev/null 2>&1 || exit 0
# JSON は Base64 で渡す (式の引用符を壊さない)。切り詰めで壊れた場合は Neovim 側が空として扱う。
encoded=$(printf '%s' "$payload" | base64 2>/dev/null | tr -d '\n')
nvim --server "$NVIM" --remote-expr "v:lua.require'workflow.agents'.signal('$slot','$event','$encoded')" >/dev/null 2>&1
exit 0
