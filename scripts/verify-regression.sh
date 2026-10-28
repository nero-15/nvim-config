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
for VERIFY_FIXTURE_MODE in silent-failure missing-timing valid; do
  export VERIFY_FIXTURE_MODE
  result=0
  out=$(bash "$ROOT/scripts/verify.sh" 2>&1) || result=$?
  if [ "$VERIFY_FIXTURE_MODE" = valid ]; then
    [ "$result" -eq 0 ] || { echo "$out"; exit 1; }
  else
    [ "$result" -ne 0 ] || { echo "false green: $VERIFY_FIXTURE_MODE"; echo "$out"; exit 1; }
  fi
done
echo 'verify harness: silent failure / missing timing / checkout isolation passed'
