local function set_terminal_keymaps()
  local opts = { buffer = 0 }
  vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
  vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
  vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
  vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
  vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
end

vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter' }, {
  pattern = { '*' },
  command = 'checktime',
})

vim.api.nvim_create_autocmd({ 'TermOpen' }, {
  pattern = { '*' },
  callback = function(_)
    vim.cmd.setlocal 'nonumber'
    vim.wo.signcolumn = 'no'
    set_terminal_keymaps()
  end,
})

-- Evita recursão infinita
local is_flipping = false

vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
  pattern = '*.md',
  callback = function()
    if is_flipping then return end

    -- Aguarda o Neovim desenhar a interface inicial (UI)
    vim.defer_fn(function()
      is_flipping = true

      local current_buf = vim.api.nvim_get_current_buf()
      local view = vim.fn.winsaveview() -- Salva posição do cursor e scroll

      -- 1. Cria um buffer fantasma
      local temp_buf = vim.api.nvim_create_buf(false, true)

      -- 2. "Vai para outro arquivo" (o fantasma)
      vim.api.nvim_win_set_buf(0, temp_buf)

      -- 3. "Volta" para a nota original imediatamente
      vim.defer_fn(function()
        vim.api.nvim_win_set_buf(0, current_buf)
        vim.fn.winrestview(view) -- Restaura posição exata

        -- Limpa o lixo
        vim.api.nvim_buf_delete(temp_buf, { force = true })
        is_flipping = false

        -- Força o redesenho final
        vim.cmd 'redraw'
      end, 50) -- Delay imperceptível de 50ms para a troca
    end, 1400) -- Aguarda 200ms após abrir o arquivo para iniciar a manobra
  end,
})
