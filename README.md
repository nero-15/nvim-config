# dotfiles-nvim

Neovim configuration for AI-driven development.

## Setup

```bash
bash setup.sh
```

Does three things:
1. Backs up existing `~/.config/nvim` if present
2. Symlinks this directory to `~/.config/nvim`
3. Initializes git repo with initial commit

Then launch `nvim`. Plugins install automatically on first run.

## Structure

```
├── init.lua              # Entry point
├── lua/
│   ├── config/
│   │   ├── options.lua   # Editor settings
│   │   ├── keymaps.lua   # Key bindings
│   │   └── autocmds.lua  # Auto commands
│   └── plugins/
│       ├── editor.lua    # neo-tree, telescope, flash, harpoon, surround
│       ├── ui.lua        # tokyonight, lualine, gitsigns, indent guides
│       ├── lsp.lua       # mason, lspconfig, nvim-cmp
│       ├── treesitter.lua
│       └── ai.lua        # claudecode.nvim, render-markdown
├── setup.sh
└── .gitignore
```

## Key Bindings

Leader: `Space`

| Key | Action |
|-----|--------|
| `<leader>e` | File explorer (neo-tree) |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>1-4` | Harpoon file 1-4 |
| `s` | Flash jump |
| `<leader>ac` | Toggle Claude Code |
| `<leader>as` | Send selection to Claude (visual mode) |
| `<leader>w` | Save |
| `gcc` | Toggle comment |
| `gd` | Go to definition |
| `K` | Hover docs |

Full list: press `<leader>` and wait for which-key popup.

## Dependencies

- Neovim >= 0.10
- git, node, ripgrep, fd
- Nerd Font (for icons)
- Claude Code (for AI integration)
- tmux (recommended)
