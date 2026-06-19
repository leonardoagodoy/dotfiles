return {
  {
    dir = vim.fn.stdpath("config"),
    name = "floating-todo",

    config = function()
      local todo_win = nil
      local todo_buf = nil

      local function close_todo()
        if todo_win and vim.api.nvim_win_is_valid(todo_win) then
          vim.api.nvim_win_close(todo_win, true)
        end

        todo_win = nil
        todo_buf = nil
      end

      local function toggle_todo()
        -- toggle
        if todo_win and vim.api.nvim_win_is_valid(todo_win) then
          close_todo()
          return
        end

        local todo_path = vim.env.TODO

        if not todo_path or todo_path == "" then
          vim.notify("TODO env var não definida", vim.log.levels.ERROR)
          return
        end

        todo_buf = vim.fn.bufadd(todo_path)
        vim.fn.bufload(todo_buf)

        vim.bo[todo_buf].filetype = "markdown"

        local width = math.floor(vim.o.columns * 0.8)
        local height = math.floor(vim.o.lines * 0.8)

        todo_win = vim.api.nvim_open_win(todo_buf, true, {
          relative = "editor",
          width = width,
          height = height,
          row = math.floor((vim.o.lines - height) / 2),
          col = math.floor((vim.o.columns - width) / 2),
          border = "single",
          -- style = "minimal",
          title = " TODO ",
        })

        vim.wo[todo_win].relativenumber = false

        vim.api.nvim_set_hl(0, "FloatBorder", {
          fg = "#ffffff",
        })

        -- q fecha
        vim.keymap.set("n", "q", close_todo, {
          buffer = todo_buf,
          silent = true,
        })

        -- auto fecha ao sair do buffer
        vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
          buffer = todo_buf,
          once = true,

          callback = function()
            vim.schedule(function()
              close_todo()
            end)
          end,
        })
      end

      vim.api.nvim_create_user_command("Todo", toggle_todo, {})

      vim.keymap.set("n", "<leader>td", toggle_todo, {
        desc = "Toggle TODO",
      })
    end,
  },
}
