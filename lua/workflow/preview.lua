-- ==========================================================
-- preview: 開いているファイルを種類に応じてブラウザで見る (R-02, R-03)
--   markdown / html / svg / asciidoc → live-preview.nvim (保存 or 入力で自動更新)
--   mermaid (.mmd)                    → mmdc で svg にしてブラウザで開く
--   pdf / 画像                        → OS の既定アプリで開く
-- ==========================================================

local M = {}

local LIVE_FILETYPES = { markdown = true, html = true, svg = true, asciidoc = true }
local OPEN_EXTENSIONS = { pdf = true, png = true, jpg = true, jpeg = true, gif = true, webp = true, xlsx = true }

local function render_mermaid(file)
  if vim.fn.executable("mmdc") == 0 then
    vim.notify("mmdc がありません: npm install -g @mermaid-js/mermaid-cli", vim.log.levels.WARN)
    return
  end
  local out = vim.fn.stdpath("cache") .. "/mermaid/" .. vim.fn.fnamemodify(file, ":t:r") .. ".svg"
  vim.fn.mkdir(vim.fn.fnamemodify(out, ":h"), "p")
  vim.system({ "mmdc", "-i", file, "-o", out, "-b", "white" }, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        vim.notify("mmdc 失敗:\n" .. (result.stderr or ""), vim.log.levels.ERROR)
        return
      end
      vim.ui.open(out)
    end)
  end)
end

function M.open()
  local file = vim.api.nvim_buf_get_name(0)
  local ft = vim.bo.filetype:match("^[^.]+") or ""
  local ext = vim.fn.fnamemodify(file, ":e"):lower()
  if file == "" then
    vim.notify("ファイルに保存してからプレビューしてください", vim.log.levels.WARN)
  elseif LIVE_FILETYPES[ft] or ext == "svg" then
    vim.cmd("LivePreview start")
  elseif ft == "mermaid" then
    vim.cmd("silent! write")
    render_mermaid(file)
  elseif OPEN_EXTENSIONS[ext] then
    vim.ui.open(file)
  else
    vim.notify("この種類はプレビュー対象外です: " .. (ft ~= "" and ft or ext), vim.log.levels.INFO)
  end
end

function M.close()
  pcall(vim.cmd, "LivePreview close")
end

return M
