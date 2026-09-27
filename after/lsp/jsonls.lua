-- jsonls: SchemaStore のスキーマで package.json / tsconfig / .claude/settings.json などを補完・検証
return {
  settings = {
    json = {
      schemas = require("schemastore").json.schemas(),
      validate = { enable = true },
    },
  },
}
