-- ==========================================================
-- Tree-sitter パーサー一覧
-- lua/plugins/treesitter.lua と setup.sh (一括インストール) の両方から使う
-- ==========================================================

return {
  "lua", "vim", "vimdoc", "query", "regex",
  "typescript", "tsx", "javascript", "jsdoc",
  "go", "gomod", "gosum", "php", "sql",
  "json", "yaml", "toml", "hcl", "terraform",
  "html", "css", "scss",
  "bash", "make", "dockerfile",
  "markdown", "markdown_inline", "mermaid",
  "gitcommit", "gitignore", "diff",
}
