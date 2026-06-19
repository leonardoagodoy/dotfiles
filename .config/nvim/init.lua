------------------------
-- configs
------------------------

vim.cmd("colorscheme oxocarbon")
vim.opt.background = "dark" -- set this to dark or light
vim.opt.number = true
vim.opt.cursorline = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 8
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.clipboard = "unnamedplus"
vim.opt.foldmethod = "indent"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

-- define leader key as space
vim.g.mapleader = " "

-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("config.lazy")
require("config.options")
require("config.keymaps")

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

-- Mapeia <leader>x para alternar o checkbox na linha atual
vim.keymap.set('n', '<leader>x', function()
  local line = vim.api.nvim_get_current_line()
  local new_line = ""

  if line:match("%[ %]") then
    -- 1. Marcar como feito e adicionar o tachado ~~
    -- A regex abaixo tenta capturar o que vem depois do [ ]
    new_line = line:gsub("%[ %]%s*(.*)", "[x] ~~%1~~")
  elseif line:match("%[x%]") then
    -- 2. Desmarcar e remover o tachado ~~
    -- Remove os ~~ do início e do fim do texto restante
    new_line = line:gsub("%[x%]%s*~~(.*)~~", "[ ] %1")
    -- Caso o checkbox esteja marcado mas não tenha ~~, apenas desmarca:
    if new_line == line then
       new_line = line:gsub("%[x%]", "[ ]")
    end
  else
    -- 3. Transforma lista comum em checkbox vazio
    new_line = line:gsub("^%s*[%*%+%-]%s+", "%0[ ] ", 1)
  end

  vim.api.nvim_set_current_line(new_line)
end, { desc = "Alternar Checkbox e Tachado Markdown" })

