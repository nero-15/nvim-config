#!/bin/bash
# setupのリンク再実行・版判定・混在plugin復元を一時ディレクトリで検証する。
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/nvim-terminal-test.XXXXXX")"
TEST_DIR="$(cd "$TEST_DIR" && pwd -P)"
trap 'rm -rf "$TEST_DIR"' EXIT

# 関数本体を読み込み、実HOMEのリンクを触らずに通常setupのリンク処理を検証。
source <(sed -n '/^link_config() {/,/^}/p' "$ROOT/setup.sh")
mkdir -p "$TEST_DIR/source"
link_config test "$TEST_DIR/source" "$TEST_DIR/new/config/nvim"
[ "$(readlink "$TEST_DIR/new/config/nvim")" = "$TEST_DIR/source" ]
link_config test "$TEST_DIR/source" "$TEST_DIR/new/config/nvim"
if compgen -G "$TEST_DIR/new/config/nvim.backup.*" >/dev/null; then
  echo "[fail] リンク再実行で不要なバックアップ" >&2; exit 1
fi
mkdir -p "$TEST_DIR/existing"
echo preserved > "$TEST_DIR/existing/file"
link_config test "$TEST_DIR/source" "$TEST_DIR/existing"
backups=("$TEST_DIR"/existing.backup.*)
[ "$(cat "${backups[0]}/file")" = preserved ]
echo "[pass] 新規親ディレクトリ・冪等リンク・既存設定バックアップ"

cat > "$TEST_DIR/ghostty" <<'STUB'
#!/bin/bash
case "$1" in
  --version) echo "Ghostty ${TEST_GHOSTTY_VERSION}" ;;
  +validate-config)
    if [ -n "${TEST_GHOSTTY_CONFIG_OUTPUT:-}" ]; then echo "$TEST_GHOSTTY_CONFIG_OUTPUT" >&2; fi
    exit "${TEST_GHOSTTY_CONFIG_STATUS:-0}" ;;
  *) exit 1 ;;
esac
STUB
chmod +x "$TEST_DIR/ghostty"
for version in 1.4.0 1.4.1 2.0.0; do
  GHOSTTY_BIN="$TEST_DIR/ghostty" TEST_GHOSTTY_VERSION="$version" bash "$ROOT/scripts/terminal-check.sh"
done
for version in 1.3.1 1.4.0-dev invalid; do
  if GHOSTTY_BIN="$TEST_DIR/ghostty" TEST_GHOSTTY_VERSION="$version" bash "$ROOT/scripts/terminal-check.sh" > "$TEST_DIR/output" 2>&1; then
    echo "[fail] 古い版/不明な版を受理: $version" >&2; exit 1
  fi
done
if GHOSTTY_BIN="$TEST_DIR/ghostty" TEST_GHOSTTY_VERSION=1.4.0 TEST_GHOSTTY_CONFIG_STATUS=1 bash "$ROOT/scripts/terminal-check.sh" > "$TEST_DIR/output" 2>&1; then
  echo "[fail] 設定エラーを受理" >&2; exit 1
fi
echo "[pass] Ghostty安定版判定・設定エラー伝播"
if GHOSTTY_BIN="$TEST_DIR/ghostty" TEST_GHOSTTY_VERSION=1.4.0 TEST_GHOSTTY_CONFIG_OUTPUT="error: SentryInitFailed" bash "$ROOT/scripts/terminal-check.sh" > "$TEST_DIR/output" 2>&1; then
  echo "[fail] exit 0の診断出力を受理" >&2; exit 1
fi

LAZY_SOURCE="${LAZY_NVIM_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim}"
if [ ! -f "$LAZY_SOURCE/lua/lazy/init.lua" ]; then
  echo "[error] lazy.nvimの実装テストには LAZY_NVIM_DIR が必要です" >&2
  exit 1
fi
mkdir -p "$TEST_DIR/config/scripts" "$TEST_DIR/plugins" "$TEST_DIR/upstream"
cp -R "$LAZY_SOURCE" "$TEST_DIR/lazy.nvim"
LAZY_SOURCE="$TEST_DIR/lazy.nvim"
cp "$ROOT/scripts/terminal-restore.lua" "$TEST_DIR/config/scripts/"
git init -q "$TEST_DIR/upstream"
echo first > "$TEST_DIR/upstream/content"
git -C "$TEST_DIR/upstream" add content
git -C "$TEST_DIR/upstream" -c user.name=Test -c user.email=test@example.invalid commit -qm first
PINNED_COMMIT="$(git -C "$TEST_DIR/upstream" rev-parse HEAD)"
echo second > "$TEST_DIR/upstream/content"
git -C "$TEST_DIR/upstream" add content
git -C "$TEST_DIR/upstream" -c user.name=Test -c user.email=test@example.invalid commit -qm second
git clone -q "$TEST_DIR/upstream" "$TEST_DIR/plugins/existing"
git clone -q "$TEST_DIR/upstream" "$TEST_DIR/upstream-missing"
TEST_BRANCH="$(git -C "$TEST_DIR/upstream" branch --show-current)"
printf '{"existing":{"branch":"%s","commit":"%s"},"missing":{"branch":"%s","commit":"%s"}}\n' \
  "$TEST_BRANCH" "$PINNED_COMMIT" "$TEST_BRANCH" "$PINNED_COMMIT" > "$TEST_DIR/config/lazy-lock.json"
cp "$TEST_DIR/config/lazy-lock.json" "$TEST_DIR/original-lock.json"
cat > "$TEST_DIR/config/init.lua" <<'LUA'
vim.opt.rtp:prepend(vim.env.LAZY_SOURCE)
require("lazy").setup({
  { name = "existing", url = "file://" .. vim.env.TEST_DIR .. "/upstream" },
  { name = "missing", url = "file://" .. vim.env.TEST_DIR .. "/upstream-missing" },
}, {
  root = vim.env.TEST_DIR .. "/plugins",
  lockfile = vim.g.nvim_setup_lockfile,
  install = { missing = not vim.g.nvim_setup_restore },
  change_detection = { enabled = not vim.g.nvim_setup_restore },
  checker = { enabled = false },
  readme = { enabled = false },
  defaults = { lazy = true },
  pkg = { enabled = false },
  headless = { process = false, log = false, task = false, colors = false },
})
LUA
TEST_DIR="$TEST_DIR" LAZY_SOURCE="$LAZY_SOURCE" \
  NVIM_LOG_FILE="$TEST_DIR/nvim.log" \
  XDG_STATE_HOME="$TEST_DIR/state" XDG_CACHE_HOME="$TEST_DIR/cache" \
  nvim --headless -u NONE -l "$TEST_DIR/config/scripts/terminal-restore.lua"
cmp "$TEST_DIR/original-lock.json" "$TEST_DIR/config/lazy-lock.json"
[ "$(git -C "$TEST_DIR/plugins/existing" rev-parse HEAD)" = "$PINNED_COMMIT" ]
[ "$(git -C "$TEST_DIR/plugins/missing" rev-parse HEAD)" = "$PINNED_COMMIT" ]
echo "[pass] 既存pluginの版ズレ＋未導入pluginを同時復元 / 元lock不変"

sed "s/$PINNED_COMMIT/0000000000000000000000000000000000000000/g" \
  "$TEST_DIR/original-lock.json" > "$TEST_DIR/config/lazy-lock.json"
cp "$TEST_DIR/config/lazy-lock.json" "$TEST_DIR/invalid-lock.json"
if TEST_DIR="$TEST_DIR" LAZY_SOURCE="$LAZY_SOURCE" \
  NVIM_LOG_FILE="$TEST_DIR/nvim.log" \
  XDG_STATE_HOME="$TEST_DIR/state" XDG_CACHE_HOME="$TEST_DIR/cache" \
  nvim --headless -u NONE -l "$TEST_DIR/config/scripts/terminal-restore.lua" > "$TEST_DIR/failure.log" 2>&1; then
  echo "[fail] 取得不能な固定版を成功扱い" >&2; exit 1
fi
cmp "$TEST_DIR/invalid-lock.json" "$TEST_DIR/config/lazy-lock.json"
echo "[pass] 復元失敗は非zero / 失敗しても元lock不変"
