local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node
local t = ls.text_node

local function box_title(args)
  local title = args[1][1] or ""
  local width = 50 -- largura total da caixa

  local padding = width - #title - 2
  if padding < 0 then padding = 0 end

  local left = math.floor(padding / 2)
  local right = padding - left

  return "┌" .. string.rep("─", left) .. " " .. title .. " " .. string.rep("─", right) .. "┐"
end

return {
  s("box", {
    f(box_title, {1}),
    t({"", "│" .. string.rep(" ", 50) .. "│", ""}),
    t("└" .. string.rep("─", 52) .. "┘"),
    t({"", ""}),
    i(1, "Titulo"),
  }),
}
