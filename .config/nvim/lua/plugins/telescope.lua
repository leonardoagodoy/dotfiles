return {
  "nvim-telescope/telescope.nvim",

  dependencies = {
    "nvim-lua/plenary.nvim",
  },

  config = function()
    require("telescope").setup({
      defaults = {
        preview = false,
        layout_strategy = "horizontal",

        layout_config = {
          horizontal = {
            preview_width = 0.55,
          },

          vertical = {
            preview_cutoff = 1,
          },
        },
      },
    })
  end,
}
