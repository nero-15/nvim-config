#!/bin/sh
# ==========================================================
# agent-gate: Claude Code の SessionStart / Stop hook (R-15)
#   start: セッション開始時の作業木 (tree ID) を控え、検証済みかどうかを文脈へ渡す
#   stop : green を確認した版と違う内容を残したまま終えようとしたら、一度だけ検証を促す
#
# 忘れ防止の補助であり、権限境界ではない。記録ファイルは書き換えられる。
# 判定できないとき (git 外など) は止めない。赤のまま報告して終えることも妨げない
# (二度目は stop_hook_active が立つので通す)。
# ==========================================================
mode=${1:-}
input=$(cat 2>/dev/null || true)
# 対象は「このセッションが今いる checkout」。worktree で動くエージェントは、その worktree を検証対象にする。
# この仕組みを持たないリポジトリへ移動していた場合は、起動したプロジェクトを見る。
session_cwd=$(printf '%s' "$input" | tr -d '\n' | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"\\]*\)".*/\1/p')
root=""
for candidate in "$session_cwd" "${CLAUDE_PROJECT_DIR:-}" "$PWD"; do
  [ -n "$candidate" ] || continue
  top=$(cd "$candidate" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null) || continue
  if [ -f "$top/scripts/agent-gate.sh" ] && [ -f "$top/scripts/tree-id.sh" ]; then root=$top; break; fi
done
[ -n "$root" ] || exit 0
cd "$root" || exit 0

tree=$(sh "$root/scripts/tree-id.sh" 2>/dev/null) || exit 0
[ -n "$tree" ] || exit 0
stamp=$(git rev-parse --git-path nvim-verify-stamp 2>/dev/null) || exit 0
sessions=$(git rev-parse --git-path nvim-sessions 2>/dev/null) || exit 0
verified=$(sed -n 's/^tree=//p' "$stamp" 2>/dev/null | head -1)
sid=$(printf '%s' "$input" | tr -d '\n' | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([A-Za-z0-9_-]*\)".*/\1/p')

case "$mode" in
  start)
    mkdir -p "$sessions" 2>/dev/null || exit 0
    find "$sessions" -type f -mtime +14 -exec rm -f {} + 2>/dev/null
    # resume / compact でも最初の基準を保つ（途中の未検証状態を基準にしない）。
    if [ -n "$sid" ] && [ ! -f "$sessions/$sid" ]; then echo "$tree" > "$sessions/$sid"; fi
    if [ "$tree" = "$verified" ]; then
      echo "作業木 tree=$tree は make check で green を確認済みの内容と一致します。"
    else
      echo "作業木 tree=$tree は make check で green を確認した記録と一致しません（記録: ${verified:-なし}）。"
    fi
    echo "変更したら make check を実行し、出力の tree: 行を証拠として報告します（docs/04-verification.md）。"
    ;;
  stop)
    case "$(printf '%s' "$input" | tr -d ' \n')" in *'"stop_hook_active":true'*) exit 0 ;; esac
    [ "$tree" = "$verified" ] && exit 0
    if [ -n "$sid" ] && [ -f "$sessions/$sid" ] && [ "$(cat "$sessions/$sid")" = "$tree" ]; then exit 0; fi
    # 同じ内容について促すのは、セッションで一度だけ（理由を報告して残した後の会話を毎回止めない）。
    if [ -n "$sid" ]; then
      if [ "$(cat "$sessions/$sid.asked" 2>/dev/null)" = "$tree" ]; then exit 0; fi
      mkdir -p "$sessions" 2>/dev/null && echo "$tree" > "$sessions/$sid.asked" 2>/dev/null
    fi
    {
      echo "作業木 tree=$tree は、make check で green を確認した内容（${verified:-記録なし}）と一致しません。"
      echo "make check を実行し、結果と tree: 行を報告してから終えてください。"
      echo "赤のまま、または未検証で残す場合は、その事実と理由を報告に明記してください（同じ内容についての案内は一度だけです）。"
    } >&2
    exit 2
    ;;
  *) exit 0 ;;
esac
exit 0
