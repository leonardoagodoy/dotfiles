return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    dashboard = {
      enabled = true,

      preset = {
        header = table.concat({
          " █▀█ █▀█ █▀▄ ▀█▀   █ █ ▀█▀ █▄█",
          " █ █ █ █ █▀▄  █    █ █  █  █ █",
          " ▀ ▀ ▀▀▀ ▀ ▀ ▀▀▀    ▀  ▀▀▀ ▀ ▀",
        }, "\n"),

        keys = {
          {
            icon = " ",
            key = "n",
            desc = "New Empty Buffer",
            action = ":enew",
          },
          {
            icon = " ",
            key = "f",
            desc = "Find File",
            action = ":Telescope find_files",
          },
          -- {
          --   icon = " ",
          --   key = "g",
          --   desc = "Live Grep",
          --   action = ":Telescope live_grep",
          -- },
          {
            icon = " ",
            key = "r",
            desc = "Recent Files",
            action = ":Telescope oldfiles",
          },
          {
            icon = " ",
            key = "c",
            desc = "Config",
            action = ":e $NVIMRC",
          },
          {
            icon = "󰒲 ",
            key = "l",
            desc = "Lazy",
            action = ":Lazy",
          },
          {
            icon = " ",
            key = "q",
            desc = "Quit",
            action = ":qa",
          },
        },
      },

      sections = {
        { section = "header" },

        -- shortcuts
        {
          section = "keys",
          gap = 1,
          padding = 1,
        },

        {
          title = "Recent Files",
          section = "recent_files",
          limit = 5,
          padding = 1,
        },

        -- startup stats
        {
          pane = 1,
          section = "startup",
          padding = 1,
        },

        -- footer custom
        -- {
        --   pane = 1,
        --   icon = " ",
        --   title = "Neovim",
        --   section = "terminal",
        --   enabled = true,
        --   cmd = "echo 'Ready to code!'",
        --   height = 1,
        --   padding = 1,
        -- },
      },
    },
  },
}
