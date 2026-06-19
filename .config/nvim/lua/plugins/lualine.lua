return {
  "nvim-lualine/lualine.nvim",
  config = function()
    -- 1. Puxa as cores do Oxocarbon
    local oxocarbon = (require("oxocarbon")).oxocarbon
    local colors = {
      color0  = oxocarbon.base02,
      color1  = oxocarbon.base10,
      color2  = oxocarbon.base08,
      color3  = oxocarbon.base00,
      color6  = oxocarbon.base04,
      color7  = oxocarbon.base09,
      color8  = oxocarbon.base14,
      color9  = oxocarbon.base12,
      color10 = oxocarbon.base13
    }

    -- 2. Monta a tabela de temas com as cores que você escolheu
    local oxocarbon_theme = {
      normal = {
        a = { fg = colors.color0, bg = colors.color7 },
        b = { fg = colors.color6, bg = colors.color3 },
        c = { fg = colors.color6, bg = colors.color3 },
        z = { fg = colors.color6, bg = colors.color3 },
      },
      insert = {
        a = { fg = colors.color0, bg = colors.color9 },
        b = { fg = colors.color6, bg = colors.color3 },
        z = { fg = colors.color9, bg = colors.color3 },
      },
      visual = {
        a = { fg = colors.color0, bg = colors.color8 },
        b = { fg = colors.color6, bg = colors.color3 },
        y = { fg = colors.color6, bg = colors.color3 },
        z = { fg = colors.color9, bg = colors.color3 },
      },
      replace = {
        a = { fg = colors.color0, bg = colors.color1 },
        b = { fg = colors.color2, bg = colors.color3 },
      },
      command = {
        a = { fg = colors.color0, bg = colors.color10 },
      },
      inactive = {
        a = { fg = colors.color0, bg = colors.color7 },
        b = { fg = colors.color6, bg = colors.color3 },
        z = { fg = colors.color0, bg = colors.color3 },
      },
    }

    -- 3. Inicializa o lualine aplicando o novo tema e mantendo seus separadores
    require('lualine').setup({
      options = { 
        theme = oxocarbon_theme, -- Trocado de 'auto' para o seu tema customizado
        component_separators = { left = '|', right = '|' },
        section_separators = { left = '', right = '|' },
      }
    })
  end
}
