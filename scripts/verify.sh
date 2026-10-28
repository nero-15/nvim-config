#!/bin/bash
# ==========================================================
# nvim-config の停止条件 (docs/04-verification.md) を 1 本で回す
# 実行: bash scripts/verify.sh   (Neovim 内なら <leader>vv / :Verify)
# ==========================================================

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

# 検証対象はこの checkout。ユーザーの別設定や state/cache を使用しない (R-21, R-22)。
# data は既存の固定済みプラグインを使い、検証のための更新は行わない。
VERIFY_DIR=$(mktemp -d "${TMPDIR:-/tmp}/nvim-verify.XXXXXX") || exit 1
trap 'rm -rf "$VERIFY_DIR"' EXIT
mkdir -p "$VERIFY_DIR/config" "$VERIFY_DIR/state" "$VERIFY_DIR/cache" || exit 1
ln -s "$ROOT" "$VERIFY_DIR/config/nvim" || exit 1
export NVIM_APPNAME=nvim
export XDG_CONFIG_HOME="$VERIFY_DIR/config"
export XDG_STATE_HOME="$VERIFY_DIR/state"
export XDG_CACHE_HOME="$VERIFY_DIR/cache"
export NVIM_LOG_FILE="$VERIFY_DIR/nvim.log"

STARTUP_BUDGET_MS=80
FAILED=0

pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAILED=1; }

echo "=== nvim-config verify ==="

# V-1: 起動エラーなし
out=$(nvim --headless "+qa" 2>&1)
code=$?
[ "$code" -eq 0 ] && [ -z "$out" ] && pass "V-1 起動エラーなし" || { fail "V-1 起動失敗 (exit $code):"; echo "$out"; }

# V-2: 全 Lua ファイルの構文
syntax_errors=""
while IFS= read -r f; do
  err=$(nvim --headless --clean -l /dev/stdin "$f" 2>&1 <<'LUA'
local ok, err = loadfile(arg[1])
if not ok then io.stderr:write(err .. "\n") os.exit(1) end
LUA
  ) || syntax_errors+="$err"$'\n'
done < <(find init.lua lua plugin after ftdetect scripts -name '*.lua' -type f)
[ -z "$syntax_errors" ] && pass "V-2 Lua 構文" || { fail "V-2 構文エラー:"; echo "$syntax_errors"; }

# V-3: 全プラグインを読み込んでもエラーが出ない
out=$(nvim --headless "+Lazy! load all" "+qa" 2>&1)
code=$?
[ "$code" -eq 0 ] && [ -z "$out" ] && pass "V-3 全プラグイン読み込み" || { fail "V-3 読み込み失敗 (exit $code):"; echo "$out"; }

# V-4: 起動時間
log="$VERIFY_DIR/startup.log"
startup_ok=1
for _ in 1 2 3; do
  nvim --headless --startuptime "$log" +qa >/dev/null 2>&1 || startup_ok=0
done
samples=$(awk '/NVIM STARTED/ && $1 ~ /^[0-9]+([.][0-9]+)?$/ {print $1}' "$log" 2>/dev/null)
ms=$(printf '%s\n' "$samples" | sort -n | head -1)
count=$(printf '%s\n' "$samples" | awk 'NF {n++} END {print n+0}')
if [ "$startup_ok" -eq 1 ] && [ "$count" -eq 3 ] && [ -n "$ms" ] && awk -v ms="$ms" -v b="$STARTUP_BUDGET_MS" 'BEGIN{exit !(ms <= b)}'; then
  pass "V-4 起動 ${ms}ms (<= ${STARTUP_BUDGET_MS}ms)"
else
  fail "V-4 起動計測失敗または予算超過 (${ms:-計測なし}ms / ${count} samples)"
fi

# V-7: スモークテスト (独自コマンド・特殊ディレクトリ・キーマップ)
out=$(nvim --headless -c "luafile scripts/smoke.lua" 2>&1)
code=$?
echo "$out" | sed 's/^/  /'
[ $code -eq 0 ] && pass "V-7 スモークテスト" || fail "V-7 スモークテスト"

# V-8: シェル関数 (aliases.sh)。ws は同名ディレクトリでも別セッションにする (#6)
tmp="$VERIFY_DIR/ws-dry-run"
mkdir -p "$tmp/client-a/api" "$tmp/client-b/api"
out=$(cd "$tmp" && bash -c '
  source "$0/aliases.sh"
  # 名前の決定性だけを検査。稼働中のサーバー/セッションの有無には依存しない。
  tmux() { return 1; }
  name() { WS_DRY_RUN=1 WS_TERMINAL=terminal ws "$1" | grep -o "attach-session -t '"'"'=[^'"'"']*" | head -1; }
  a=$(name client-a/api); b=$(name client-b/api); a2=$(name "$PWD/client-a/api/")
  [ -n "$a" ] && [ "$a" != "$b" ] && [ "$a" = "$a2" ] || { echo "a=$a b=$b a2=$a2"; exit 1; }
' "$ROOT" 2>&1)
code=$?
[ "$code" -eq 0 ] && [ -z "$out" ] && pass "V-8 ws のセッション名" || { fail "V-8 ws のセッション名 (exit $code):"; echo "$out"; }

echo ""
if [ $FAILED -eq 0 ]; then
  echo "green ✓"
else
  echo "red ✗"
fi
exit $FAILED
