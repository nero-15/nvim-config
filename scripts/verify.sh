#!/bin/bash
# ==========================================================
# nvim-config の停止条件 (docs/04-verification.md) を 1 本で回す
# 実行: bash scripts/verify.sh   (Neovim 内なら <leader>vv / :Verify)
# ==========================================================

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

STARTUP_BUDGET_MS=80
FAILED=0

pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAILED=1; }

echo "=== nvim-config verify ==="

# V-1: 起動エラーなし
out=$(nvim --headless "+qa" 2>&1)
[ -z "$out" ] && pass "V-1 起動エラーなし" || { fail "V-1 起動時の出力:"; echo "$out"; }

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
[ -z "$out" ] && pass "V-3 全プラグイン読み込み" || { fail "V-3 読み込み時の出力:"; echo "$out"; }

# V-4: 起動時間
log=$(mktemp)
for _ in 1 2 3; do nvim --headless --startuptime "$log" +qa >/dev/null 2>&1; done
ms=$(grep "NVIM STARTED" "$log" | awk '{print $1}' | sort -n | head -1)
rm -f "$log"
if awk -v ms="$ms" -v b="$STARTUP_BUDGET_MS" 'BEGIN{exit !(ms <= b)}'; then
  pass "V-4 起動 ${ms}ms (<= ${STARTUP_BUDGET_MS}ms)"
else
  fail "V-4 起動 ${ms}ms (> ${STARTUP_BUDGET_MS}ms)"
fi

# V-7: スモークテスト (独自コマンド・特殊ディレクトリ・キーマップ)
out=$(nvim --headless -c "luafile scripts/smoke.lua" 2>&1)
code=$?
echo "$out" | sed 's/^/  /'
[ $code -eq 0 ] && pass "V-7 スモークテスト" || fail "V-7 スモークテスト"

echo ""
if [ $FAILED -eq 0 ]; then
  echo "green ✓"
else
  echo "red ✗"
fi
exit $FAILED
