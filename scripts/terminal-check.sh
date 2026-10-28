#!/bin/bash
# Ghostty のバージョンと設定だけを検証。アプリやセッションを起動・変更しない。
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GHOSTTY_EXECUTABLE="${GHOSTTY_BIN:-}"
if [ -z "$GHOSTTY_EXECUTABLE" ]; then
  for candidate in /Applications/Ghostty.app/Contents/MacOS/ghostty \
    "$HOME/Applications/Ghostty.app/Contents/MacOS/ghostty"; do
    if [ -x "$candidate" ]; then GHOSTTY_EXECUTABLE="$candidate"; break; fi
  done
fi
if [ -z "$GHOSTTY_EXECUTABLE" ]; then GHOSTTY_EXECUTABLE="$(command -v ghostty || true)"; fi
if [ -z "$GHOSTTY_EXECUTABLE" ] || [ ! -x "$GHOSTTY_EXECUTABLE" ]; then
  echo "[error] Ghostty が見つかりません。インストール後に再実行してください。" >&2
  exit 1
fi

version_output="$("$GHOSTTY_EXECUTABLE" --version)"
version_line="${version_output%%$'\n'*}"
echo "$version_line"
if [[ "$version_line" =~ ^Ghostty\ ([0-9]+)\.([0-9]+)\.([0-9]+)($|[[:space:]]) ]]; then
  major="${BASH_REMATCH[1]}"
  minor="${BASH_REMATCH[2]}"
  if (( major < 1 || (major == 1 && minor < 4) )); then
    echo "[error] Ghostty 1.4.0以上が必要です。bash setup.sh --upgrade-ghostty を実行してください。" >&2
    exit 1
  fi
else
  echo "[error] 安定版のバージョンを確認できません: $version_line" >&2
  exit 1
fi
if ! validation_output="$("$GHOSTTY_EXECUTABLE" +validate-config --config-file="$SCRIPT_DIR/ghostty/config" 2>&1)"; then
  printf '%s\n' "$validation_output" >&2
  exit 1
fi
if [ -n "$validation_output" ]; then
  # 一部の初期化失敗はCLIがexit 0でもstderrへ出る。成功扱いにしない。
  printf '%s\n' "$validation_output" >&2
  exit 1
fi
echo "[pass] Ghostty 1.4以上 / リポジトリの設定"
