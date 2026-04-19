-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

require 'config.keymap'
require 'quarto_tmp'

---@module 'lazy'
---@type LazySpec
return {
  {
    'joenyrcouto/obsidian.nvim',
    version = '*',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
      workspaces = { { name = 'brain', path = '~/Documents/brain' } },
      allowed_extensions = { '.md', '.qmd', '.base', '.js', '.excalidraw' },
      writable_extensions = { '.md', '.qmd', '.base' },
      templates = {
        folder = '99-brutos/templates',
        date_format = '%Y-%m-%d',
        time_format = '%H:%M',
        template_mappings = {
          ['00-rápidas'] = '00-rápidas-tlp.md',
          ['01-notelm'] = '01-notelm-tlp.md',
          ['02-zettel'] = '02-zettel-tlp.md',
          ['03-moc'] = '03-moc-tlp.md',
          ['99-brutos/biblioteca'] = '99-acervo-tlp.md',
          ['99-brutos/tracking'] = '99-tracking-tlp.md',
          ['99-brutos/exercícios'] = '99-exercícios-tlp.md',
        },
        templater_compat = true,
      },
      daily_notes = {
        folder = '99-brutos/diárias',
        date_format = '%Y-%m-%d',
        template = '99-tracking-tlp.md',
      },
      attachments = {
        img_folder = '99-brutos/anexos',
        img_text_func = function(client, path)
          local name = vim.fs.basename(tostring(path))
          return string.format('![[%s]]', name)
        end,
      },
      ui = { enable = true, checkboxes = {}, bullets = {} }, -- Ativa seu validador de links laranja/vermelho
      legacy_commands = false,
    },
    config = function(_, opts) require('obsidian').setup(opts) end,
  },

  {
    'oflisback/obsidian-bridge.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
      obsidian_server_address = 'http://localhost:27123',
      extensions = { '.md', '.qmd', '.base' },
    },
  },

  {
    'olimorris/codecompanion.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('codecompanion').setup {
        strategies = { chat = { adapter = 'lmstudio' }, inline = { adapter = 'lmstudio' } },
        adapters = {
          lmstudio = function()
            return require('codecompanion.adapters').extend('openai_compatible', {
              env = { url = 'http://localhost:1234' },
            })
          end,
        },
      }
    end,
  },

  {
    'kdheepak/lazygit.nvim',
    cmd = 'LazyGit',
    keys = { { '<leader>gg', '<cmd>LazyGit<CR>', desc = 'Open LazyGit' } },
    dependencies = { 'nvim-lua/plenary.nvim' },
  },

  {
    '3rd/image.nvim',
    opts = {},
  },

  {
    'olimorris/codecompanion.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('codecompanion').setup {
        strategies = { chat = { adapter = 'lmstudio' }, inline = { adapter = 'lmstudio' } },
        adapters = {
          lmstudio = function()
            return require('codecompanion.adapters').extend('openai_compatible', {
              env = { url = 'http://localhost:1234' },
            })
          end,
        },
      }
    end,
  },
}
