#!/bin/sh
# ==========================================================
# tree-id: 作業木の内容を 1 つの ID で表す (R-15)
#   HEAD の SHA は未コミットの変更を区別できない。追跡中の変更と、無視されていない
#   未追跡ファイルを含めた内容を tree オブジェクトの SHA にする。
#   同じ内容なら誰が計算しても同じ ID になるので、Maker と Checker が「同じ版」を照合できる。
#
# 使い方: sh scripts/tree-id.sh [-v] [dir]
#   既定は tree SHA だけを出力。-v は HEAD と変更ファイル数も出力する。
# 実際の index・作業木・HEAD は変更しない（一時 index を使う）。
# .claude/worktrees 以下（並走エージェントの worktree）は含めない。
# 変更ファイルの blob は .git/objects に書かれるが、参照されないため git gc で消える。
# ==========================================================
set -u

verbose=0
if [ "${1:-}" = "-v" ]; then verbose=1; shift; fi
if [ -n "${1:-}" ]; then cd "$1" || exit 1; fi

command -v git >/dev/null 2>&1 || { echo "tree-id: git が見つかりません" >&2; exit 1; }
root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "tree-id: git リポジトリの外です" >&2; exit 1; }
cd "$root" || exit 1

tmp=$(mktemp "${TMPDIR:-/tmp}/tree-id.XXXXXX") || exit 1
trap 'rm -f "$tmp" "$tmp.lock"' EXIT INT TERM
# 実 index を写して stat 情報を再利用する（変更のないファイルを読み直さない）。
index=$(git rev-parse --git-path index)
# -p で時刻を保つ: index より後に書かれた同サイズの変更を git が見落とさないため (racy git)。
if [ -f "$index" ]; then cp -p "$index" "$tmp" || exit 1; else rm -f "$tmp"; fi

# エージェントの worktree (.claude/worktrees) は別の作業木。親の ID に含めない
# (含めると、並走エージェントが commit するたびに親の ID が変わる)。
# (除外 pathspec は、その場所が .gitignore 済みだと git add が失敗するため、足してから一時 index から外す)
GIT_INDEX_FILE="$tmp" git add -A . >/dev/null 2>&1 || { echo "tree-id: 作業木を読めません" >&2; exit 1; }
GIT_INDEX_FILE="$tmp" git rm -r -q --cached --ignore-unmatch -- .claude/worktrees >/dev/null 2>&1 \
  || { echo "tree-id: worktree を除外できません" >&2; exit 1; }
tree=$(GIT_INDEX_FILE="$tmp" git write-tree 2>/dev/null) || { echo "tree-id: tree を作れません" >&2; exit 1; }

if [ "$verbose" -eq 0 ]; then
  echo "$tree"
  exit 0
fi
head=$(git rev-parse --verify --quiet HEAD 2>/dev/null || echo "none")
changed=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
echo "tree: $tree"
echo "head: $head"
echo "uncommitted: $changed"
