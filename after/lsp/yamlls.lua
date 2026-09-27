-- yamlls: SchemaStore のスキーマで GitHub Actions / compose / amplify.yml などを補完・検証
return {
  settings = {
    yaml = {
      schemaStore = { enable = false, url = "" }, -- SchemaStore.nvim 側のカタログを使う
      schemas = require("schemastore").yaml.schemas(),
      keyOrdering = false,
    },
  },
}
