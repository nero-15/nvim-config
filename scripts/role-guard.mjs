// This is an accidental-operation guard, not a shell sandbox.
import { readFileSync } from "node:fs";
import { basename } from "node:path";

const fail = (reason) => { throw new Error(reason); };

// Parse only ordinary commands. Reject expansion/heredocs instead of attempting
// to interpret executable shell syntax or accidentally hiding command bodies.
function commands(source) {
  if (/[\x00\r]/.test(source) || /\$|\x60|<<|\\\n/.test(source)) {
    fail("展開・ヒアドキュメントは判定できません。単純なコマンドへ分けてください");
  }
  const result = [];
  let tokens = [], word = "", quote = "", escaped = false;
  const flush = () => { if (word) { tokens.push(word); word = ""; } };
  for (const char of source) {
    if (escaped) { word += char; escaped = false; continue; }
    if (char === "\\" && quote !== "'") { escaped = true; continue; }
    if (quote) { if (char === quote) quote = ""; else word += char; continue; }
    if (char === "'" || char === '"') { quote = char; continue; }
    if (";&|\n".includes(char)) {
      flush();
      if (tokens.length) result.push(tokens);
      tokens = [];
    } else if ("<>".includes(char)) { flush(); tokens.push(char); }
    else if (/\s/.test(char)) flush();
    else word += char;
  }
  if (quote || escaped) fail("閉じていない引用符・エスケープ");
  flush();
  if (tokens.length) result.push(tokens);
  if (!result.length) fail("空のコマンド");
  return result;
}

function gitArgs(tokens) {
  let index = 1;
  while (index < tokens.length && tokens[index].startsWith("-")) {
    if (["-C", "-c", "--git-dir", "--work-tree"].includes(tokens[index])) index += 2;
    else index += 1;
  }
  return tokens.slice(index);
}

function check(role, tokens) {
  const executable = basename(tokens[0]);
  if (role === "checker" && (tokens.includes(">") || tokens.includes("<"))) fail("Checkerはリダイレクトしません");
  if (["env", "command", "sudo", "eval", "exec", "xargs"].includes(executable)
    || tokens[0].includes("=") || tokens.some((token) => /[(){}]/.test(token))) {
    fail("ラッパー・複合シェル構文は判定できません");
  }
  if (["bash", "sh", "zsh", "fish"].includes(executable) && tokens.includes("-c")) {
    fail("shell -c は判定できません");
  }
  if (executable === "gh") {
    const gh = tokens.slice(1);
    while (gh[0]?.startsWith("-")) {
      const option = gh.shift();
      if (["-R", "--repo", "--hostname"].includes(option)) gh.shift();
    }
    if (gh[0] === "pr" && ["merge", "review", "comment"].includes(gh[1])) {
      fail("PRの公開・承認・マージは主担当へ返してください");
    }
    if (role === "checker") fail("Checkerは外部操作を主担当へ返してください");
  }
  if (executable === "git") {
    if (tokens.some(token => token.startsWith("-c") || token.startsWith("--config-env"))) {
      fail("gitの一時設定変更は主担当へ返してください");
    }
    const [operation, ...args] = gitArgs(tokens);
    if (operation === "push") {
      // Require a destination ref so current branch/push.default cannot target main.
      if (args.some(arg => ["<", ">"].includes(arg) || arg.startsWith("#"))) {
        fail("pushのリダイレクト・コメントは判定できません。単純なコマンドにしてください");
      }
      const positional = [];
      let options = true;
      const flags = new Set(["-u", "--set-upstream", "-f", "--force", "--force-with-lease",
        "-n", "--dry-run", "--porcelain", "-v", "--verbose", "-q", "--quiet", "--atomic"]);
      for (const arg of args) {
        if (options && arg === "--") { options = false; continue; }
        if (options && arg.startsWith("-")) {
          // Value-taking/unknown flags can hide an implicit push. Fail closed
          // instead of mistaking their values for a remote or destination ref.
          if (!flags.has(arg) && !arg.startsWith("--force-with-lease=")) {
            fail("未対応のpushオプションです。remoteと作業ブランチを単純な形で明示してください");
          }
        } else positional.push(arg);
      }
      if (positional.length < 2) {
        fail("暗黙/全ブランチpushは禁止。作業ブランチを明示してください");
      }
      for (const ref of positional.slice(1)) {
        const destination = ref.replace(/^\+/, "").split(":").at(-1);
        if (!destination || ["main", "refs/heads/main", "HEAD"].includes(destination) || destination.includes("*")) {
          fail("mainまたは未確定の参照へのpushは禁止");
        }
      }
    }
    if (role === "checker") {
      const allowed = ["status", "diff", "log", "show", "rev-parse", "ls-files", "ls-tree", "describe"];
      if (!allowed.includes(operation)
        || tokens.some((token) => token === "-c" || /^--(output|ext-diff|textconv|exec-path)(=|$)/.test(token))) {
        fail("Checkerのgit操作は読み取りだけです");
      }
    }
    return;
  }
  if (role !== "checker") return;
  if (executable === "make" && tokens.length === 2 && ["check", "verify"].includes(tokens[1])) return;
  if (executable === "bash" && tokens.length === 2 && tokens[1] === "scripts/verify.sh") return;
  const readers = ["pwd", "ls", "cat", "head", "tail", "wc", "stat", "readlink", "file", "rg", "grep", "true", "false"];
  if (!readers.includes(executable)) fail("Checkerの未対応コマンドです。Read/Grep/Globか主担当を利用してください");
  if (executable === "rg" && tokens.some((token) => /^--pre(=|$)/.test(token))) fail("rg --preは禁止");
}

try {
  const role = process.argv[2];
  if (!["maker", "checker"].includes(role)) fail("不明なrole");
  const input = JSON.parse(readFileSync(0, "utf8"));
  if (input?.tool_name !== "Bash" || typeof input?.tool_input?.command !== "string") fail("不正なhook入力");
  for (const tokens of commands(input.tool_input.command)) check(role, tokens);
} catch (error) {
  process.stderr.write(`role-guard: ${error.message}\n`);
  process.exitCode = 2;
}
