// No models, network, or repository mutations: mock workflow runtime + hook input.
import assert from "node:assert/strict";
import { readFileSync, mkdtempSync, rmSync } from "node:fs";
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
    "make check", "make verify", "bash scripts/verify.sh",
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
