// No models, network, or repository mutations: mock workflow runtime + hook input.
import assert from "node:assert/strict";
import { readFileSync, writeFileSync, mkdirSync, mkdtempSync, rmSync, cpSync, existsSync, realpathSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("..", import.meta.url));
const guard = join(root, "scripts/role-guard.sh");
let passed = 0;
function test(name, fn) {
  return Promise.resolve().then(fn).then(() => { passed++; console.log("PASS " + name); });
}
function invokeGuard(role, command, options = {}) {
  return spawnSync("/bin/sh", [guard, role], {
    encoding: "utf8",
    input: JSON.stringify({ tool_name: "Bash", tool_input: { command } }),
    ...options,
  });
}
await test("maker blocks self approval and every push", () => {
  for (const command of [
    "gh pr merge 1", "gh -R org/repo pr merge 1", "gh pr review 1 --approve", "gh pr comment 1 --body hi",
    "git push", "git push origin", "git push origin HEAD", "git push origin main",
    "git push origin +main", "git push origin :main", "git push origin HEAD:refs/heads/main",
    "git -C /tmp push origin 'HEAD:main'", "git --git-dir=/tmp/g push --mirror origin",
    "git push origin feature; git push origin main", "git push origin feature\ngh pr merge 1",
    "bash -c 'git push origin main'", "git -c alias.publish='push origin main' publish",
    "git -calias.publish='push origin HEAD:main' publish",
    "git push -o ci.skip origin", "git push --receive-pack git-receive-pack origin",
    "git push --repo origin", "git push --push-option=ci.skip origin",
    "git push origin > /tmp/push.log", "git push origin # no explicit branch",
    "git push origin :", "git push origin +:",
    "git push origin @",
    "git push -u origin codex/graph", "git push origin HEAD:refs/heads/codex/graph",
    "git push origin feature/main-menu && gh pr create --base main",
    "git push --force-with-lease origin codex/graph",
    "git push --force-with-lease=refs/heads/codex/graph:abc origin HEAD:codex/graph",
  ]) assert.equal(invokeGuard("maker", command).status, 2, command);
});
await test("maker can implement, integrate and verify locally", () => {
  for (const command of [
    "git status", "git merge origin/main", "git add lua/workflow/spec.lua",
    "make check", "node scripts/graph-tests.mjs",
  ]) assert.equal(invokeGuard("maker", command).status, 0, command);
});
await test("checker permits reading and documented verification", () => {
  for (const command of [
    "git status --short", "git -C /tmp show HEAD:docs/00-dna.md",
    "git diff --stat | head -20", "rg -n workflow lua", "cat docs/04-verification.md",
    "make check", "make verify", "make tree-id", "bash scripts/verify.sh",
  ]) assert.equal(invokeGuard("checker", command).status, 0, command);
});
await test("checker blocks writes, arbitrary code and external publication", () => {
  for (const command of [
    "git commit -m test", "git push origin codex/x", "git checkout main",
    "git diff > changed.txt", "git diff --output=changed.txt", "git status 2>/tmp/result",
    "cat docs/tasks.md > docs/copy.md", "sed -i '' s/a/b/ docs/tasks.md", "tee docs/tasks.md",
    "node -e 'process.exit()'", "bash scripts/terminal-restore.lua", "make setup",
    "rg --pre=evil test", "gh issue comment 1 --body test", "env git status",
    "git show $(touch bad)", "cat <<'EOF'\ngit push origin main\nEOF",
  ]) assert.equal(invokeGuard("checker", command).status, 2, command);
});
await test("hook fails closed for malformed input and missing dependency", () => {
  for (const input of ["", "{", "null", "[]", "{}", '{"tool_name":"Bash","tool_input":{"command":1}}']) {
    assert.equal(invokeGuard("maker", "", { input }).status, 2, input);
  }
  assert.equal(invokeGuard("unknown", "git status").status, 2);
  const empty = mkdtempSync(join(tmpdir(), "nvim-role-path-"));
  try {
    assert.equal(invokeGuard("maker", "git status", { env: { PATH: empty } }).status, 2);
  } finally { rmSync(empty, { recursive: true }); }
});
await test("role definitions inherit the model and restrict checker tools", () => {
  for (const name of ["maker", "checker"]) {
    const role = readFileSync(join(root, ".claude/agents", name + ".md"), "utf8");
    assert.match(role, /^model: inherit$/m);
    assert.match(role, /matcher: Bash/);
    assert.ok(role.includes('sh "$CLAUDE_PROJECT_DIR/scripts/role-guard.sh" ' + name));
  }
  assert.match(readFileSync(join(root, ".claude/agents/checker.md"), "utf8"), /^tools: Read, Glob, Grep, Bash$/m);
});

// ── 版ID (tree-id) と Stop ゲート (R-15)。一時リポジトリだけを使う ──
const sh = (cwd, file, args = [], options = {}) => spawnSync("/bin/sh", [join(root, "scripts", file), ...args], {
  cwd, encoding: "utf8", ...options,
});
const git = (cwd, ...args) => {
  const result = spawnSync("git", ["-c", "user.name=Graph Test", "-c", "user.email=graph@example.invalid", ...args],
    { cwd, encoding: "utf8" });
  assert.equal(result.status, 0, `git ${args.join(" ")}: ${result.stderr}`);
  return result.stdout.trim();
};
function fixtureRepo() {
  const dir = realpathSync(mkdtempSync(join(tmpdir(), "nvim-tree-id-")));
  git(dir, "init", "-q");
  writeFileSync(join(dir, ".gitignore"), "ignored.log\n");
  writeFileSync(join(dir, "a.txt"), "one\n");
  mkdirSync(join(dir, "scripts"));
  for (const name of ["agent-gate.sh", "tree-id.sh"]) cpSync(join(root, "scripts", name), join(dir, "scripts", name));
  git(dir, "add", "-A");
  git(dir, "commit", "-qm", "first");
  return dir;
}
await test("tree-id identifies uncommitted content without touching the index", () => {
  const dir = fixtureRepo();
  try {
    const id = () => { const r = sh(dir, "tree-id.sh"); assert.equal(r.status, 0, r.stderr); return r.stdout.trim(); };
    const clean = id();
    assert.match(clean, /^[0-9a-f]{40,64}$/);
    assert.equal(clean, git(dir, "rev-parse", "HEAD^{tree}"), "clean tree equals the committed tree");
    writeFileSync(join(dir, "ignored.log"), "noise\n");
    assert.equal(id(), clean, "ignored files do not change the ID");
    writeFileSync(join(dir, "a.txt"), "two\n");
    const modified = id();
    assert.notEqual(modified, clean, "tracked edits change the ID");
    writeFileSync(join(dir, "new file.txt"), "untracked\n");
    const untracked = id();
    assert.notEqual(untracked, modified, "untracked files change the ID");
    assert.equal(id(), untracked, "same content gives the same ID");
    assert.equal(git(dir, "diff", "--cached", "--name-only"), "", "real index must stay untouched");
    assert.equal(git(dir, "status", "--porcelain"), "M a.txt\n?? \"new file.txt\"".trim());
    // 同じ内容を commit しても ID は変わらない（検証済みの記録が commit 後も使える）
    git(dir, "add", "-A");
    git(dir, "commit", "-qm", "second");
    assert.equal(id(), untracked);
    const verbose = sh(dir, "tree-id.sh", ["-v"]).stdout;
    assert.match(verbose, new RegExp(`^tree: ${untracked}\\nhead: [0-9a-f]+\\nuncommitted: 0\\n$`));
    // commit と同じ秒に、同じサイズで書き換えた内容も見落とさない（index の時刻を保たないと取りこぼす）
    writeFileSync(join(dir, "a.txt"), "aaa\n");
    git(dir, "commit", "-qam", "racy base");
    const racyBase = id();
    writeFileSync(join(dir, "a.txt"), "bbb\n");
    spawnSync("sleep", ["1.1"]);
    assert.notEqual(id(), racyBase, "same-size edit right after a commit must change the ID");
    git(dir, "checkout", "-q", "--", "a.txt");
    git(dir, "reset", "-q", "--hard", "HEAD~1");
    assert.equal(id(), untracked);
    const sub = join(dir, "scripts");
    assert.equal(sh(sub, "tree-id.sh").stdout.trim(), untracked, "subdirectory resolves the same checkout");
    const outside = mkdtempSync(join(tmpdir(), "nvim-no-git-"));
    try { assert.notEqual(sh(outside, "tree-id.sh").status, 0, "outside git must fail, not print an ID"); }
    finally { rmSync(outside, { recursive: true }); }
    // 並走エージェントの worktree を作っても、そこで commit しても、親の ID は変わらない
    const worktree = join(dir, ".claude", "worktrees", "agent-x");
    git(dir, "worktree", "add", "-q", worktree, "-b", "agent-x");
    assert.equal(id(), untracked, "creating an agent worktree must not change the parent ID");
    writeFileSync(join(worktree, "a.txt"), "agent work\n");
    const inside = sh(worktree, "tree-id.sh").stdout.trim();
    assert.notEqual(inside, untracked, "the worktree has its own ID");
    git(worktree, "commit", "-qam", "agent commit");
    assert.equal(id(), untracked, "a commit inside the agent worktree must not change the parent ID");
    assert.equal(sh(worktree, "tree-id.sh").stdout.trim(), inside);
    // その場所を .gitignore に入れていても、入れていなくても計算できる
    writeFileSync(join(dir, ".gitignore"), "ignored.log\n.claude/worktrees/\n");
    assert.match(id(), /^[0-9a-f]{40,64}$/, "ignored worktree directory must not break the ID");
  } finally { rmSync(dir, { recursive: true }); }
});
await test("stop gate asks once for unverified changes and never traps the session", () => {
  const dir = fixtureRepo();
  try {
    const gate = (mode, input, env = {}) => sh(dir, "agent-gate.sh", [mode], {
      input: JSON.stringify(input), env: { PATH: process.env.PATH, CLAUDE_PROJECT_DIR: dir, ...env },
    });
    const tree = () => sh(dir, "tree-id.sh").stdout.trim();
    const session = { session_id: "abc-123", cwd: dir };
    const started = gate("start", session);
    assert.equal(started.status, 0, started.stderr);
    assert.ok(started.stdout.includes("一致しません") && started.stdout.includes(tree()), started.stdout);
    assert.equal(gate("stop", session).status, 0, "a session that changed nothing may stop");
    writeFileSync(join(dir, "a.txt"), "changed by the agent\n");
    const blocked = gate("stop", session);
    assert.equal(blocked.status, 2);
    assert.ok(blocked.stderr.includes("make check") && blocked.stderr.includes(tree()), blocked.stderr);
    assert.equal(blocked.stdout, "");
    assert.equal(gate("stop", { ...session, stop_hook_active: true }).status, 0, "second stop reports red instead of looping");
    // 理由を報告して残したあとの会話を、同じ内容で毎回止めない。内容が変わればもう一度促す
    assert.equal(gate("stop", session).status, 0, "the same content is asked about once per session");
    writeFileSync(join(dir, "a.txt"), "changed again\n");
    assert.equal(gate("stop", session).status, 2, "new content is asked about again");
    // resume / compact で SessionStart が再度来ても、未検証の現在地を基準にしない
    assert.equal(gate("start", { ...session, source: "resume" }).status, 0);
    writeFileSync(join(dir, "a.txt"), "changed after resume\n");
    assert.equal(gate("stop", session).status, 2);
    assert.equal(gate("stop", { session_id: "other", cwd: dir }).status, 2, "a session without a baseline needs the green record");
    // green の記録が今の内容と一致すれば通る。その後に変えたらまた促す
    writeFileSync(join(dir, ".git", "nvim-verify-stamp"), `tree=${tree()}\nhead=x\nat=now\n`);
    assert.equal(gate("stop", session).status, 0);
    assert.ok(gate("start", { session_id: "later", cwd: dir }).stdout.includes("一致します"));
    writeFileSync(join(dir, "b.txt"), "after verification\n");
    assert.equal(gate("stop", session).status, 2);
    writeFileSync(join(dir, ".gitignore"), "ignored.log\n.claude/worktrees/\n");
    // worktree のセッションは、その worktree の内容で判定する
    const worktree = join(dir, ".claude", "worktrees", "fix-a");
    git(dir, "add", "-A");
    git(dir, "commit", "-qm", "third");
    git(dir, "worktree", "add", "-q", worktree, "-b", "fix-a");
    const inWorktree = { session_id: "wt-1", cwd: worktree };
    assert.equal(gate("start", inWorktree).status, 0);
    writeFileSync(join(worktree, "a.txt"), "worktree edit\n");
    assert.equal(gate("stop", inWorktree).status, 2);
    assert.ok(existsSync(join(dir, ".git", "worktrees", "fix-a", "nvim-sessions", "wt-1")), "baseline is per worktree");
    // 入力を読めなくても、hook の作業ディレクトリがこのリポジトリなら判定する。git の外では止めない
    for (const input of ["", "{", "null"]) {
      const result = sh(dir, "agent-gate.sh", ["stop"], { input, env: { PATH: process.env.PATH, CLAUDE_PROJECT_DIR: tmpdir() } });
      assert.equal(result.status, 2, "unparsable input falls back to the hook's working directory");
    }
    const outside = mkdtempSync(join(tmpdir(), "nvim-no-git-"));
    try {
      const result = sh(outside, "agent-gate.sh", ["stop"], { input: "{}", env: { PATH: process.env.PATH } });
      assert.equal(result.status, 0, "outside the repository the gate stays out of the way");
      assert.equal(sh(dir, "agent-gate.sh", ["unknown"], { input: "{}" }).status, 0);
    } finally { rmSync(outside, { recursive: true }); }
  } finally { rmSync(dir, { recursive: true }); }
});
await test("project settings wire the gate and keep verification prompt-free", () => {
  const settings = JSON.parse(readFileSync(join(root, ".claude/settings.json"), "utf8"));
  for (const [event, mode] of [["SessionStart", "start"], ["Stop", "stop"]]) {
    assert.equal(settings.hooks[event][0].hooks[0].command, `sh "$CLAUDE_PROJECT_DIR/scripts/agent-gate.sh" ${mode}`);
  }
  for (const rule of ["Bash(make check)", "Bash(make tree-id)"]) assert.ok(settings.permissions.allow.includes(rule), rule);
  assert.ok(!settings.permissions.allow.some(rule => /push|commit|\*/.test(rule)), "no publishing or wildcard rules");
  const maker = readFileSync(join(root, ".claude/agents/maker.md"), "utf8");
  assert.ok(maker.includes('sh "$CLAUDE_PROJECT_DIR/scripts/agent-gate.sh" stop'), "maker subagent is gated too");
});

const source = readFileSync(join(root, ".claude/workflows/audit.js"), "utf8");
assert.ok(source.startsWith("export const meta = {"));
assert.doesNotMatch(source, /\bimport\s*\(|\bmodel\s*:/);
const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
const workflow = new AsyncFunction("args", "agent", "parallel", "phase", "log", source.replace("export const meta", "const meta"));
const revision = "a".repeat(40);
const base = { lens: "起動失敗", targets: ["lua/a.lua"], revision };
const finding = { file: "lua/a.lua", line: 3, claim: "入力xで起動が失敗する", evidence: "要求R-21とlua/a.lua:3" };
const found = (findings = [], notChecked = []) => ({ checkedRevision: revision, findings, notChecked });
const vote = (verdict = "upheld") => ({ checkedRevision: revision, verdict, reason: "調査した理由", evidence: "docs/02-requirements.md:1" });
async function run(args, respond) {
  let active = 0, maximum = 0;
  const calls = [], phases = [];
  const agent = async (prompt, options) => {
    assert.ok(prompt.includes(revision));
    calls.push(options.label);
    active++;
    maximum = Math.max(maximum, active);
    try {
      await new Promise(resolve => setTimeout(resolve, 1));
      return await respond(options.label, prompt);
    } finally { active--; }
  };
  const parallel = tasks => Promise.all(tasks.map(task => Promise.resolve().then(task).catch(() => null)));
  const result = await workflow(args, agent, parallel, value => phases.push(value), () => {});
  return { result, maximum, calls, phases };
}
await test("audit requires explicit bounded args before spawning", async () => {
  for (const args of [
    undefined, {}, { ...base, revision: "HEAD" }, { ...base, revision: "dirty" },
    { ...base, targets: [] }, { ...base, targets: ["a", "a"] },
    { ...base, targets: Array.from({ length: 13 }, (_, i) => String(i)) },
    { ...base, concurrency: 4 }, { ...base, context: {} },
  ]) {
    let calls = 0;
    await assert.rejects(() => workflow(args, () => { calls++; }, () => {}, () => {}, () => {}));
    assert.equal(calls, 0);
  }
});
await test("audit confirms only two independent upheld verdicts", async () => {
  const { result, calls, phases } = await run(base, label => label.startsWith("find:") ? found([finding]) : vote());
  assert.equal(result.confirmed.length, 1);
  assert.equal(result.complete, true);
  assert.deepEqual(calls, ["find:lua/a.lua", "refute:0:0:0", "refute:0:0:1"]);
  assert.deepEqual(phases, ["Find", "Refute"]);
});
await test("audit retains refuted and unknown results separately", async () => {
  for (const verdict of ["refuted", "unverified"]) {
    const { result } = await run(base, label => label.startsWith("find:") ? found([finding]) : vote(verdict));
    assert.equal(result.confirmed.length, 0);
    assert.equal(result[verdict === "refuted" ? "refuted" : "unverified"].length, 1);
    assert.equal(result.complete, verdict === "refuted");
  }
});
await test("audit exposes unchecked scope even with no findings", async () => {
  const { result } = await run(base, () => found([], ["実画面未確認"]));
  assert.equal(result.notChecked.length, 1);
  assert.equal(result.complete, false);
});
await test("audit keeps disagreeing counterchecks unresolved", async () => {
  for (const first of ["upheld", "refuted"]) {
    const second = first === "upheld" ? "refuted" : "upheld";
    const { result } = await run(base, label => label.startsWith("find:") ? found([finding])
      : vote(label.endsWith(":0") ? first : second));
    assert.equal(result.unverified.length, 1);
    assert.equal(result.refuted.length, 0);
    assert.equal(result.confirmed.length, 0);
    assert.equal(result.complete, false);
  }
});
await test("audit preserves find failures and mismatched revisions", async () => {
  for (const respond of [
    () => null, () => { throw new Error("offline"); }, () => ({}),
    () => ({ ...found(), checkedRevision: "b".repeat(40) }),
    () => found(Array(6).fill(finding)), () => found([{}]),
  ]) {
    const { result, calls } = await run(base, respond);
    assert.equal(result.failedTargets.length, 1);
    assert.equal(result.complete, false);
    assert.equal(calls.length, 1);
  }
});
await test("audit preserves failed counterchecks as unknown", async () => {
  for (const response of [null, {}, { ...vote(), checkedRevision: "b".repeat(40) }]) {
    const { result } = await run(base, label => label.startsWith("find:") ? found([finding]) : response);
    assert.equal(result.failedChecks.length, 2);
    assert.equal(result.unverified.length, 1);
    assert.equal(result.confirmed.length, 0);
    assert.equal(result.complete, false);
  }
});
await test("audit obeys global concurrency bounds in both phases", async () => {
  for (const concurrency of [2, 3]) {
    const targets = Array.from({ length: 7 }, (_, i) => "target" + i);
    const { result, maximum, calls } = await run({ ...base, targets, concurrency }, label =>
      label.startsWith("find:") ? found([finding, finding]) : vote());
    assert.equal(maximum, concurrency);
    assert.equal(result.confirmed.length, 14);
    assert.equal(calls.length, 35);
  }
});
console.log(`PASS graph tests: ${passed} groups (mock runtime only; no LLM runs)`);
