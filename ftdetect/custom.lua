-- 標準で判定されない/誤判定されるファイルの種類を補う
vim.filetype.add({
  extension = {
    mmd = "mermaid",
    mermaid = "mermaid",
    mdx = "markdown.mdx",
  },
  filename = {
    ["compose.yaml"] = "yaml.docker-compose",
    ["compose.yml"] = "yaml.docker-compose",
    [".golangci.yml"] = "yaml",
    ["TASKS.md"] = "markdown",
  },
  pattern = {
    [".*/%.claude/settings.*%.json"] = "jsonc", -- コメントを許容
    [".*/%.github/workflows/.*%.ya?ml"] = "yaml.github",
  },
})
