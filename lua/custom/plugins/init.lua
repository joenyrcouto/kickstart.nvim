-- init.lua completo e refatorado

---@module 'lazy'
---@type LazySpec

-- 1. Caminhos e Bootstrapping
local obsidian_fork_path = vim.fn.expand '~/Documents/git/obsidian.nvim'
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'

-- 2. Configuração do Luarocks (Essencial para o processamento de imagens)
package.path = package.path .. ';' .. vim.fn.expand '$HOME' .. '/.luarocks/share/lua/5.1/?/init.lua;'
package.path = package.path .. ';' .. vim.fn.expand '$HOME' .. '/.luarocks/share/lua/5.1/?.lua;'

-----------------------------------------------------------
-- INTEGRAÇÃO QUARTO / DATA SCIENCE / CONFIGS GLOBAIS
-----------------------------------------------------------
require 'config.global'
require 'config.autocommands'
require 'config.keymap'
require 'config.redir'
require 'quarto_tmp'

-- Configurações de visualização para Markdown/Quarto (Estilo Obsidian)
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown', 'quarto' },
  callback = function()
    vim.opt_local.conceallevel = 2
    vim.opt_local.concealcursor = 'nvci' -- Mostra Unicode mesmo no modo de inserção
  end,
})

-- Ativa Treesitter e Otter para suporte a código embutido
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'quarto', 'markdown' },
  callback = function() require('otter').activate({ 'julia', 'python', 'r' }, true, true, nil) end,
})

-----------------------------------------------------------
-- SETUP DE PLUGINS (Lazy.nvim)
-----------------------------------------------------------
return {
  -- Gestão de Git
  {
    'kdheepak/lazygit.nvim',
    cmd = 'LazyGit',
    keys = { { '<leader>gg', '<cmd>LazyGit<CR>', desc = 'Open LazyGit' } },
    dependencies = { 'nvim-lua/plenary.nvim' },
  },

  -- 1. PLUGIN PRINCIPAL: GESTÃO DO VAULT (SEU FORK)
  {
    'joenyrcouto/obsidian.nvim',
    version = '*',
    lazy = false,
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

  -- 2. RENDERIZADOR VISUAL (O "TRADUTOR" DE LATEX E TABELAS)
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    opts = {
      -- Configuração de LaTeX (O Tradutor Unicode automático)
      latex = {
        enabled = true,
        converter = 'latex2text', -- Tenta usar latex se disponível, senão usa Unicode
        highlight = 'RenderMarkdownMath',
        render_modes = { 'n', 'c', 't', 'i' },
      },
      -- Evita conflitos de ocultação de texto
      anti_conceal = {
        enabled = true,
        ignore = {
          'latex',
          'latex2text', -- Ignora blocos de latex ($$ ... $$)
          'inline_formula', -- Ignora fórmulas inline ($ ... $)
          'math_environment', -- Ignora ambientes matemáticos
        },
      },
      -- Ícone para links de imagem
      link = {
        enabled = true,
        image = '󰄄 ',
        wiki = { enabled = true }, -- WikiLinks do Obsidian
      },
    },
  },

  -- 3. MOTOR DE IMAGEM (FORÇA BRUTA PARA LINKS LOCAIS)
  {
    'vhyrro/luarocks.nvim',
    priority = 1001,
    opts = { rocks = { 'magick' } },
  },
  {
    '3rd/image.nvim',
    dependencies = { 'luarocks.nvim' },
    opts = {
      backend = 'kitty',
      processor = 'magick_cli',
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { 'markdown', 'vimwiki', 'quarto' },

          -- A GAMBIARRA: Interceptação e busca forçada
          resolve_image_path = function(document_path, image_path, fallback_path)
            -- 1. Ignora URLs
            if image_path:match '^https?://' then return fallback_path end

            -- 2. Limpeza de sintaxe Wikilink
            local clean_path = image_path:gsub('^!?%[%[', ''):gsub('%]%]$', '')
            local filename = vim.fn.fnamemodify(clean_path, ':t')
            local vault_path = vim.fn.expand '~/Documents/brain'

            -- 3. Lógica para Excalidraw (Prioridade SVG)
            if filename:match '%.excalidraw' then
              local target_svg = filename:gsub('%.md$', '')
              if not target_svg:match '%.svg$' then target_svg = target_svg .. '.svg' end

              local found_svg = vim.fn.findfile(target_svg, vault_path .. '/**')
              if found_svg ~= '' then return vim.fn.fnamemodify(found_svg, ':p') end
            end

            -- 4. Lógica para Imagens Normais (PNG, JPG, etc.)
            local found_normal = vim.fn.findfile(filename, vault_path .. '/**')
            if found_normal ~= '' then return vim.fn.fnamemodify(found_normal, ':p') end

            return fallback_path
          end,
        },
      },
      max_width = 100,
      max_height = 12,
      window_overlap_clear_enabled = true,
    },
  },

  -- 4. TREESITTER (O MOTOR DE IDENTIFICAÇÃO)
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    opts = {
      ensure_installed = {
        'markdown',
        'markdown_inline',
        'latex',
        'python',
        'r',
        'julia',
        'lua',
        'bash',
      },
      highlight = { enable = true },
    },
  },

  -- 5. OUTROS PLUGINS (CodeCompanion, Bridge, etc.)
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
}
