#!/bin/sh
# Claude Code PreToolUse(Bash)専用。誤操作抑止でありsandboxではない。
# 依存欠落・JSON不正・内部例外もfail-closedでexit 2。
if [ "$#" -ne 1 ]; then echo "role-guard: maker または checker を指定してください" >&2; exit 2; fi
if ! command -v node >/dev/null 2>&1; then echo "role-guard: Node.js が必要です" >&2; exit 2; fi
guard_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)" || exit 2
node "$guard_dir/role-guard.mjs" "$1"
result=$?
if [ "$result" -ne 0 ]; then exit 2; fi
exit 0
