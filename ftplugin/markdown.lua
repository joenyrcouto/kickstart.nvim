vim.b.slime_cell_delimiter = '```'

-- wrap text, but by word no character
-- indent the wrappped line
vim.wo.wrap = true
vim.wo.linebreak = true
vim.wo.breakindent = true
vim.wo.showbreak = '|'

vim.api.nvim_create_autocmd('BufEnter', {
  desc = 'Automatically pull when entering a buffer in my ~/notes/ directory',
  pattern = vim.fn.expand '~' .. '/notes/*.md' .. ',' .. vim.fn.expand '~' .. '/notes/*.qmd',
  group = vim.api.nvim_create_augroup('git_pull', { clear = true }),
  callback = function(ev)
    local file = ev.file
    vim.fn.jobstart('git pull', {
      on_exit = function()
        vim.fn.jobstart('git add ' .. file, {
          on_exit = function()
            vim.fn.jobstart('git commit -m "sync"', {
              on_exit = function() print 'git pulled' end,
            })
          end,
        })
      end,
    })
  end,
})

vim.api.nvim_create_autocmd('BufWritePost', {
  desc = 'Automatically push git when saving in my ~/notes/ directory',
  pattern = vim.fn.expand '~' .. '/notes/*.md' .. ',' .. vim.fn.expand '~' .. '/notes/*.qmd',
  group = vim.api.nvim_create_augroup('git_push', { clear = true }),
  callback = function(ev)
    local file = ev.file
    vim.fn.jobstart('git add ' .. file, {
      on_exit = function()
        vim.fn.jobstart('git commit -m "sync"', {
          on_exit = function()
            vim.fn.jobstart('git push', {
              on_exit = function() print 'git pushed' end,
            })
          end,
        })
      end,
    })
  end,
})
