-- R-06: real asynchronous verification keeps its origin and complete lines.
-- Run: nvim --clean --headless -l scripts/workflow-verify.lua
local repo = vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, 'S').source:sub(2)))
vim.opt.runtimepath:prepend(repo)
local verify = require('workflow.verify')
local original_cwd = vim.fn.getcwd()
local temp = vim.fn.tempname()
vim.fn.mkdir(temp, 'p')
temp = vim.uv.fs_realpath(temp)
local notifications = {}
vim.notify = function(message) notifications[#notifications + 1] = message end
vim.api.nvim_create_user_command('VerifyLog', verify.show_log, {})
local function eq(actual, expected)
  assert(vim.deep_equal(actual, expected), vim.inspect({ actual = actual, expected = expected }))
end
local function write(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.fn.writefile(lines, path)
end
local function wait_done()
  assert(vim.wait(5000, function()
    for _, msg in ipairs(notifications) do
      if msg:match('red ✗') or msg:match('green ✓') or msg:find('再検証してください', 1, true) then return true end
    end
    return false
  end), 'verify did not finish: ' .. vim.inspect(notifications))
end
local ok, err = xpcall(function()
  local a, b = temp .. '/project A', temp .. '/project B'
  local detect_dir = temp .. '/detection'
  write(detect_dir .. '/package.json', { '{"scripts":{"check":"check command","verify":"verify command"}}' })
  write(detect_dir .. '/pnpm-lock.yaml', {})
  eq(verify.detect(detect_dir, 'check'), { 'pnpm', 'run', 'check' })
  eq(verify.detect(detect_dir), { 'pnpm', 'run', 'verify' })
  eq(verify.detect(detect_dir, 'verify'), { 'pnpm', 'run', 'verify' })
  write(detect_dir .. '/package.json', { '{"scripts":{"typecheck":"tsc","verify":"full"}}' })
  eq(verify.detect(detect_dir, 'check'), nil)
  write(detect_dir .. '/Makefile', { 'check:', '\t@true' })
  eq(verify.detect(detect_dir, 'check'), { 'make', 'check' })
  vim.fn.delete(detect_dir .. '/Makefile')
  write(detect_dir .. '/scripts/check.sh', { 'exit 0' })
  eq(verify.detect(detect_dir, 'check'), { 'bash', 'scripts/check.sh' })
  write(a .. '/src/main.go', { 'first project' })
  write(b .. '/src/main.go', { 'second project' })
  write(a .. '/scripts/verify.sh', {
    "printf 'src/ma'", 'sleep 0.15',
    "printf 'src/err' >&2", 'sleep 0.15',
    "printf 'in.go:1:1: split stdout 日本語\\n'", 'sleep 0.15',
    "printf 'or.go:2:3: split stderr\\n' >&2",
    "printf 'src/missing.go:3:4: no newline'", 'exit 1',
  })
  vim.cmd.tcd(vim.fn.fnameescape(a))
  verify.run()
  vim.cmd.tabnew()
  vim.cmd.tcd(vim.fn.fnameescape(b))
  wait_done()
  local qf = vim.fn.getqflist({ items = 1, context = 1, title = 1 })
  local valid = vim.tbl_filter(function(i) return i.valid == 1 end, qf.items)
  eq(#valid, 3)
  for i, path in ipairs({ '/src/main.go', '/src/error.go', '/src/missing.go' }) do
    eq(vim.api.nvim_buf_get_name(valid[i].bufnr), a .. path)
  end
  eq(valid[1].text, 'split stdout 日本語')
  eq(valid[2].text, 'split stderr')
  eq(valid[3].text, 'no newline')
  eq(vim.fn.getcwd(), b)
  eq(vim.fn.haslocaldir(), 0)
  eq(vim.fn.haslocaldir(-1, 0), 1)
  eq(vim.fn.getcwd(-1, -1), original_cwd)
  eq(qf.context.root, a)
  eq(qf.context.mode, 'verify')
  eq(qf.context.exit_code, 1)
  assert(qf.context.started_at and qf.context.finished_at, 'missing timestamps')
  assert(qf.title:find(a, 1, true), 'title lacks project root')
  verify.show_log()
  local log = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
  assert(log:find(a, 1, true), 'log lacks origin')
  vim.cmd.close()
  -- Opening the same log repeatedly must not fail with E95 duplicate name.
  verify.show_log()
  verify.show_log()
  vim.cmd('tabonly!')
  vim.cmd('only!')
  vim.cmd('enew!')
  -- A save failure must prevent the verifier from launching against stale files.
  write(a .. '/scripts/verify.sh', { "printf started > launched" })
  vim.cmd.tcd(vim.fn.fnameescape(a))
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'unsaved unnamed buffer' })
  notifications = {}
  verify.run()
  vim.wait(200)
  assert(vim.uv.fs_stat(a .. '/launched') == nil, 'verify ran after failed save')
  assert(table.concat(notifications, '\n'):find('保存'), 'save failure was not explained')
  vim.bo.modified = false
  -- No-output success still has an inspectable result and does not reuse old errors.
  write(a .. '/scripts/verify.sh', { 'exit 0' })
  notifications = {}
  verify.run()
  wait_done()
  eq(#vim.fn.getqflist(), 0)
  verify.show_log()
  log = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
  assert(log:find('exit: 0', 1, true), 'empty success lacks outcome')
  vim.cmd.close()
  -- A changed HEAD is an observation to recheck, not an unconditional green.
  local function git(args)
    local cmd = { 'git', '-c', 'user.name=Verify Test', '-c', 'user.email=verify@example.invalid' }
    vim.list_extend(cmd, args)
    local result = vim.system(cmd, { cwd = a, text = true }):wait()
    assert(result.code == 0, result.stderr)
    return vim.trim(result.stdout)
  end
  git({ 'init', '-q' })
  git({ 'commit', '--allow-empty', '-qm', 'first' })
  local first = git({ 'rev-parse', 'HEAD' })
  git({ 'commit', '--allow-empty', '-qm', 'second' })
  local second = git({ 'rev-parse', 'HEAD' })
  git({ 'update-ref', 'HEAD', first })
  write(a .. '/scripts/verify.sh', { 'git update-ref HEAD ' .. second })
  notifications = {}
  verify.run()
  wait_done()
  local context = vim.fn.getqflist({ context = 1 }).context
  eq(context.started_head, first)
  eq(context.finished_head, second)
  assert(not table.concat(notifications, '\n'):find('green ✓', 1, true), 'changed HEAD reported green')

  -- Daily check uses its own command and cannot overlap or stand in for verify.
  write(a .. '/scripts/check.sh', { 'sleep 0.15', 'printf checked > checked' })
  write(a .. '/scripts/verify.sh', { 'printf verified > verified' })
  notifications = {}
  verify.run('check')
  verify.run()
  assert(table.concat(notifications, '\n'):find('check は実行中', 1, true), 'cross-mode guard missing')
  wait_done()
  local checked = vim.fn.getqflist({ context = 1, title = 1 })
  eq(checked.context.mode, 'check')
  eq(checked.context.command, { 'bash', 'scripts/check.sh' })
  assert(checked.title:find('Check', 1, true), 'check title missing')
  assert(vim.uv.fs_stat(a .. '/checked'), 'check command did not run')
  assert(not vim.uv.fs_stat(a .. '/verified'), 'verify ran during check')
  verify.show_log()
  log = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
  assert(log:find('mode: check', 1, true), 'check log mode missing')
  assert(log:find('command: bash scripts/check.sh', 1, true), 'check log command missing')
  vim.cmd.close()
  vim.fn.delete(a .. '/scripts/check.sh')
  notifications = {}
  verify.run('check')
  vim.wait(200)
  assert(table.concat(notifications, '\n'):find('check コマンドが見つかりません', 1, true), 'missing check not explained')
  assert(not vim.uv.fs_stat(a .. '/verified'), 'missing check fell back to verify')

end, debug.traceback)
vim.cmd('silent! tabonly!')
vim.cmd('silent! only!')
vim.cmd.cd(vim.fn.fnameescape(original_cwd))
vim.fn.delete(temp, 'rf')
if not ok then io.stderr:write(err .. '\n'); vim.cmd('cq!') end
io.write('workflow check/verify: modes, guard, origin, streams, metadata, save failure, logs passed\n')
vim.cmd('qa!')
