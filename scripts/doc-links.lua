-- R-04/R-13: ファイルリンクと docs/README.md からの到達性。節アンカー/外部URLは検査しない。
local root = vim.fs.normalize(arg[1] or vim.fs.dirname(vim.fs.dirname(vim.fn.fnamemodify(arg[0], ":p"))))
local docs, edges, errors, scanned = {}, {}, {}, {}
local function is_document(path)
  return path:match("%.md$") or path:match("%.html$")
end
local function collect(dir)
  for name, kind in vim.fs.dir(dir) do
    local path = dir .. "/" .. name
    if kind == "directory" then collect(path)
    elseif kind == "file" and is_document(path) then docs[path] = true end
  end
end
local function relative(path) return vim.fs.relpath(root, path) or path end
local function error_at(path, line, message)
  errors[#errors + 1] = relative(path) .. ":" .. line .. ": " .. message
end
local function scan(path)
  if scanned[path] then return end
  scanned[path], edges[path] = true, {}
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then error_at(path, 1, "cannot read document"); return end
  local function link(raw, line)
    local target = raw:match("^%s*<([^>]+)>") or raw:match("^%s*(%S+)") or ""
    if target:match("^[%a][%w+.-]*:") or target:match("^//") then return end
    target = target:gsub("[#?].*$", ""):gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end)
    if target == "" then return end
    if target:sub(1, 1) == "/" then error_at(path, line, "use a portable relative link: " .. target); return end
    local dest = vim.fs.normalize(vim.fs.dirname(path) .. "/" .. target)
    local stat = vim.uv.fs_stat(dest)
    if not stat then error_at(path, line, "missing link: " .. target); return end
    if stat.type == "file" and is_document(dest) then edges[path][dest] = true end
  end
  local function html_links(line, index)
    for target in line:gmatch('[Hh][Rr][Ee][Ff]%s*=%s*"([^"]+)"') do link("<" .. target .. ">", index) end
    for target in line:gmatch("[Hh][Rr][Ee][Ff]%s*=%s*'([^']+)'") do link("<" .. target .. ">", index) end
    for target in line:gmatch('[Ss][Rr][Cc]%s*=%s*"([^"]+)"') do link("<" .. target .. ">", index) end
    for target in line:gmatch("[Ss][Rr][Cc]%s*=%s*'([^']+)'") do link("<" .. target .. ">", index) end
  end
  local function label(value) return vim.trim(value):gsub("%s+", " "):lower() end
  local fence, prose_lines, references = nil, {}, {}
  for index, line in ipairs(lines) do
    if path:match("%.md$") then
      local marker = line:match("^%s*(```+)") or line:match("^%s*(~~~+)")
      if marker then
        if not fence then fence = marker
        elseif marker:sub(1, 1) == fence:sub(1, 1) and #marker >= #fence then fence = nil end
      elseif not fence then
        -- 定義を先に集め、実際に参照されるリンクだけ到達経路にする。
        local prose = line:gsub("`+[^`]*`+", "")
        local name, target = prose:match("^%s*%[([^%]]+)%]:%s*(.+)")
        if name then references[label(name)] = references[label(name)] or target
        else prose_lines[index] = prose end
      end
    else
      html_links(line, index)
    end
  end
  for index, prose in pairs(prose_lines) do
    html_links(prose, index)
    prose = prose:gsub("%b[]%(([^%)]+)%)", function(target) link(target, index); return "" end)
    prose = prose:gsub("%[([^%]]+)%]%[([^%]]*)%]", function(text, name)
      local target = references[label(name ~= "" and name or text)]
      if target then link(target, index) end
      return ""
    end)
    for name in prose:gmatch("%[([^%]]+)%]") do
      local target = references[label(name)]
      if target then link(target, index) end
    end
  end
end

if vim.fn.isdirectory(root .. "/docs") ~= 1 then
  io.stderr:write("docs directory missing: " .. root .. "\n"); os.exit(1)
end
collect(root .. "/docs")
for path in pairs(docs) do scan(path) end
for _, name in ipairs({ "README.md", "AGENTS.md", "CLAUDE.md" }) do
  if vim.fn.filereadable(root .. "/" .. name) == 1 then scan(root .. "/" .. name) end
end
local reached = {}
local function visit(path)
  if reached[path] then return end
  reached[path] = true
  scan(path)
  for dest in pairs(edges[path] or {}) do visit(dest) end
end
visit(root .. "/docs/README.md")
local count = 0
for path in pairs(docs) do
  count = count + 1
  if not reached[path] then error_at(path, 1, "not reachable from docs/README.md") end
end
table.sort(errors)
if #errors > 0 then
  io.stderr:write(table.concat(errors, "\n") .. "\n"); os.exit(1)
end
io.write(string.format("docs: %d documents reachable / file links valid\n", count))
