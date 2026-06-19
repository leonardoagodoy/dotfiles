return {
  "nvim-tree/nvim-tree.lua",

  dependencies = {
    "nvim-tree/nvim-web-devicons"
  },

  config = function()
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    vim.opt.termguicolors = true

    require("nvim-tree").setup({
      update_focused_file = {
        enable = true,
      },

      sort = {
        sorter = "case_sensitive",
      },

      view = {
        width = 30,
      },

      renderer = {
        group_empty = true,
      },

      filters = {
        dotfiles = true,
      },

      git = {
        enable = true,
      },
    })
  end
}
