#!/bin/bash
# R-06/R-21: silent failure・計測欠落を green にしない。実 nvim は起動しない。
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export VERIFY_FIXTURE_ROOT="$ROOT"
nvim() {
  [ "$(readlink "$XDG_CONFIG_HOME/nvim")" = "$VERIFY_FIXTURE_ROOT" ] || return 99
  case "$*" in
    *--clean*|*-c*) return 0 ;;
  esac
  [ "$VERIFY_FIXTURE_MODE" != silent-failure ] || return 42
  while [ "$#" -gt 0 ]; do
    if [ "$1" = --startuptime ]; then
      shift
      if [ "$VERIFY_FIXTURE_MODE" != missing-timing ]; then
        echo '020.000  001.000: --- NVIM STARTED ---' >> "$1"
      fi
      break
    fi
    shift
  done
  return 0
}
export -f nvim
# 本テストはshellの成否判定だけが対象。graphテストは外側のV-10で実行する。
node() { return 0; }
export -f node
# 偽の nvim で得た green を、実チェックアウトの検証済み記録にしない (R-15)。記録先を一時ファイルへ向ける。
STAMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/verify-stamp.XXXXXX")
PROBE="$ROOT/.verify-regression-probe"
trap 'rm -rf "$STAMP_DIR"; rm -f "$PROBE"' EXIT
export NVIM_VERIFY_STAMP_FILE="$STAMP_DIR/stamp"
# 前回が強制終了されて残った probe を先に消す（残ったままだと最初の検査が内容変化と誤判定する）。
rm -f "$PROBE"
for VERIFY_FIXTURE_MODE in silent-failure missing-timing valid; do
  export VERIFY_FIXTURE_MODE
  rm -f "$NVIM_VERIFY_STAMP_FILE"
  result=0
  out=$(bash "$ROOT/scripts/verify.sh" 2>&1) || result=$?
  if [ "$VERIFY_FIXTURE_MODE" = valid ]; then
    [ "$result" -eq 0 ] || { echo "$out"; exit 1; }
    grep -q '^tree=[0-9a-f]\{40,\}$' "$NVIM_VERIFY_STAMP_FILE" || { echo "green did not record the verified tree"; echo "$out"; exit 1; }
  else
    [ "$result" -ne 0 ] || { echo "false green: $VERIFY_FIXTURE_MODE"; echo "$out"; exit 1; }
    [ ! -e "$NVIM_VERIFY_STAMP_FILE" ] || { echo "red recorded a verified tree: $VERIFY_FIXTURE_MODE"; exit 1; }
  fi
done
# 検証中に内容が変わったら、exit 0 でも検証済みの記録を残さない。
rm -f "$NVIM_VERIFY_STAMP_FILE"
VERIFY_FIXTURE_MODE=valid
nvim() { : > "$VERIFY_FIXTURE_ROOT/.verify-regression-probe"; case "$*" in *--startuptime*) ;; *) return 0 ;; esac
  while [ "$#" -gt 0 ]; do if [ "$1" = --startuptime ]; then echo '020.000  001.000: --- NVIM STARTED ---' >> "$2"; break; fi; shift; done; return 0; }
export -f nvim
out=$(bash "$ROOT/scripts/verify.sh" 2>&1) || { echo "$out"; exit 1; }
rm -f "$PROBE"
[ ! -e "$NVIM_VERIFY_STAMP_FILE" ] || { echo "content changed during verify but a verified tree was recorded"; exit 1; }
case "$out" in *"検証中に作業木が変わりました"*) ;; *) echo "content change during verify was not reported"; echo "$out"; exit 1 ;; esac
echo 'verify harness: silent failure / missing timing / checkout isolation / stamp conditions passed'
