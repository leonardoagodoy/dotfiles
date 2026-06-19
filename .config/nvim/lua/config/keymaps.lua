local keymap = vim.keymap.set

local wk = require("which-key")
wk.add({
  { "<leader>f", group = "file" }, -- group
  { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File", mode = "n" },
  { "<leader>fb", function() print("hello") end, desc = "Foobar" },
  { "<leader>fn", desc = "New File" },
  { "<leader>w", proxy = "<c-w>", group = "windows" }, -- proxy to window mappings
  { "<leader>b", group = "buffers", expand = function()
      return require("which-key.extras").expand.buf()
    end
  },
  {
    -- Nested mappings are allowed and can be added in any order
    -- Most attributes can be inherited or overridden on any level
    -- There's no limit to the depth of nesting
    mode = { "n", "v" }, -- NORMAL and VISUAL mode
    { "<leader>q", "<cmd>q<cr>", desc = "Quit" }, -- no need to specify mode since it's inherited
    { "<leader>w", "<cmd>w<cr>", desc = "Write" },
  }
})

------------------------
-- lines management
------------------------

-- mover blocos selecionados
keymap("v", "<A-Down>", ":m '>+1<CR>gv=gv")
keymap("v", "<A-Up>", ":m '<-2<CR>gv=gv")

-- mover linha atual
keymap("n", "<A-Up>", ":m -2<CR>")
keymap("n", "<A-Down>", ":m +1<CR>")

-- indentacao mantando selecao
keymap("v", ">", ">gv")
keymap("v", "<", "<gv")

------------------------
-- shortcuts
------------------------

keymap({ "n", "i", "v" }, "<C-s>", "<cmd>w<CR><ESC>", {
  desc = "Save file",
})

keymap({ "n", "i", "v" }, "<C-z>", "<cmd>undo<CR><ESC>", {
  desc = "Undo last change",
})

keymap({ "n", "i", "v" }, "<C-S-z>", "<cmd>redo<CR><ESC>", {
  desc = "Redo last change",
})

keymap("n", "<C-f>", "/")

------------------------
-- tools
------------------------

keymap("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", {
  desc = "Toggle NvimTree",
})

keymap("n", "<C-p>", "<cmd>Telescope find_files<CR>", {
  desc = "Find files",
})

------------------------
-- buffers
------------------------

keymap({ "n" }, "<leader>bb", "<cmd>bnext<CR>", {
  desc = "Next buffer",
})

keymap({ "n" }, "<leader>bv", "<cmd>bprevious<CR>", {
  desc = "Previous buffer",
})

