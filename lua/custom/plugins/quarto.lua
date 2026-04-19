return {
  -- Quarto + Otter
  {
    'quarto-dev/quarto-nvim',
    dependencies = {
      {
        'jmbuhr/otter.nvim',
        opts = {
          lsp = {},
          buffers = {
            set_filetype = true,
          },
        },
      },
      'jpalardy/vim-slime',
      'nvim-treesitter/nvim-treesitter',
      'jbyuki/nabla.nvim',
      '3rd/image.nvim',
    },
    opts = {
      lspFeatures = {
        languages = { 'r', 'python', 'julia', 'bash', 'lua', 'html', 'dot' },
      },
    },
  },

  -- Treesitter + textobjects
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    branch = 'main',
    lazy = false,
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    opts = {
      ensure_installed = {
        'r',
        'python',
        'markdown',
        'markdown_inline',
        'julia',
        'bash',
        'yaml',
        'lua',
        'vim',
        'query',
        'vimdoc',
        'latex',
        'html',
        'css',
        'dot',
      },
      highlight = { enable = true, additional_vim_regex_highlighting = false },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = 'gnn',
          node_incremental = 'grn',
          scope_incremental = 'grc',
          node_decremental = 'grm',
        },
      },
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ['af'] = '@function.outer',
            ['if'] = '@function.inner',
            ['ac'] = '@class.outer',
            ['ic'] = '@class.inner',
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = { [']m'] = '@function.outer', [']]'] = '@class.inner' },
          goto_next_end = { [']M'] = '@function.outer', [']['] = '@class.outer' },
          goto_previous_start = { ['[m'] = '@function.outer', ['[['] = '@class.inner' },
          goto_previous_end = { ['[M'] = '@function.outer', ['[]'] = '@class.outer' },
        },
      },
    },
  },

  -- LSP moderno (sem lspconfig.setup)
  {
    'neovim/nvim-lspconfig', -- ainda necessário para alguns utilitários (ex.: lspconfig.util)
    event = 'BufReadPre',
    dependencies = {
      'mason-org/mason.nvim',
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      'hrsh7th/cmp-nvim-lsp', -- para capabilities
      'folke/neodev.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
    },
    config = function()
      require('mason').setup()
      require('mason-lspconfig').setup { automatic_installation = true }

      local cmp_nvim_lsp = require 'cmp_nvim_lsp'
      local capabilities = cmp_nvim_lsp.default_capabilities()

      -- Função on_attach (será usada via autocmd LspAttach)
      local function on_attach(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        local bufnr = event.buf

        -- ===== JULIALS: RESTRINGIR A ARQUIVOS .jl =====
        if client.name == 'julials' then
          local ft = vim.bo[bufnr].filetype
          -- Se não for julia, desativa completamente o cliente neste buffer
          if ft ~= 'julia' and ft ~= 'quarto' then
            client:stop()
            return
          end
          -- Para arquivos julia, desabilita funcionalidades problemáticas
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
          client.server_capabilities.documentHighlightProvider = false
          client.server_capabilities.semanticTokensProvider = false
        end

        vim.api.nvim_create_autocmd('LspAttach', {
          callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client and client.name == 'obsidian' then
              -- Desabilita completamente o diagnóstico de links
              client.server_capabilities.diagnosticProvider = false
              -- Ou, se preferir desabilitar apenas um tipo específico:
              -- vim.lsp.diagnostic.enable(false, args.buf)
            end
          end,
        })

        vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'
        local opts = { noremap = true, silent = true, buffer = bufnr }

             -- Highlight de referências (opcional)
        if client and client:supports_method('textDocument/documentHighlight', bufnr) then
          local group = vim.api.nvim_create_augroup('lsp-highlight-' .. bufnr, { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = bufnr,
            group = group,
            callback = vim.lsp.buf.document_highlight,
          })
          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = bufnr,
            group = group,
            callback = vim.lsp.buf.clear_references,
          })
          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('lsp-detach-' .. bufnr, { clear = true }),
            callback = function() vim.lsp.buf.clear_references() end,
          })
        end
      end

      -- Registrar o autocmd globalmente
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('user-lsp-attach', { clear = true }),
        callback = on_attach,
      })

      -- Configuração dos servidores via vim.lsp.config (NOVA API)
      local servers = {
        r_language_server = {
          filetypes = { 'r', 'rmd', 'quarto' },
        },
        cssls = {},
        html = {},
        emmet_language_server = {},
        dotls = {},
        julials = {
          cmd = { 'julia', '--startup-file=no', '--history-file=no', '-e', 'using LanguageServer; runserver()' },
          filetypes = { 'julia', 'quarto', 'markdown' }, -- só ativa nesses tipos
        },
        bashls = {
          filetypes = { 'sh', 'bash', 'zsh' },
        },
        pyright = {
          filetypes = { 'python' },
          settings = {
            python = {
              analysis = {
                autoSearchPaths = true,
                diagnosticMode = 'openFilesOnly',
              },
            },
          },
        },
      }

      -- Para cada servidor, configurar e habilitar
      for name, server_opts in pairs(servers) do
        -- Mescla capabilities no server_opts
        server_opts.capabilities = capabilities
        vim.lsp.config(name, server_opts)
        vim.lsp.enable(name)
      end

      -- Instalação automática com Mason
      local ensure_installed = vim.tbl_keys(servers)
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }
    end,
  },

  -- nvim-cmp (mantido exatamente como original)
  {
    'hrsh7th/nvim-cmp',
    branch = 'main',
    event = 'InsertEnter',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-nvim-lsp-signature-help',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-calc',
      'hrsh7th/cmp-emoji',
      'saadparwaiz1/cmp_luasnip',
      'f3fora/cmp-spell',
      'ray-x/cmp-treesitter',
      'kdheepak/cmp-latex-symbols',
      'jmbuhr/cmp-pandoc-references',
      {
        'L3MON4D3/LuaSnip',
        dependencies = { 'rafamadriz/friendly-snippets' },
        config = function()
          require('luasnip.loaders.from_vscode').lazy_load()
          require('luasnip.loaders.from_vscode').lazy_load { paths = { vim.fn.stdpath 'config' .. '/snips' } }
          local luasnip = require 'luasnip'
          luasnip.filetype_extend('quarto', { 'markdown' })
          luasnip.filetype_extend('rmarkdown', { 'markdown' })
        end,
      },
      'onsails/lspkind-nvim',
      {
        'zbirenbaum/copilot.lua',
        opts = {
          suggestion = {
            enabled = true,
            auto_trigger = true,
            debounce = 75,
            keymap = {
              accept = '<c-a>',
              accept_word = false,
              accept_line = false,
              next = '<M-]>',
              prev = '<M-[>',
              dismiss = '<C-]>',
            },
          },
          panel = { enabled = false },
        },
      },
    },
    config = function()
      local cmp = require 'cmp'
      local luasnip = require 'luasnip'
      local lspkind = require 'lspkind'
      lspkind.init()

      local has_words_before = function()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match '%s' == nil
      end

      cmp.setup {
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = {
          ['<C-f>'] = cmp.mapping.scroll_docs(-4),
          ['<C-d>'] = cmp.mapping.scroll_docs(4),
          ['<C-n>'] = cmp.mapping(function(fallback)
            if luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
              fallback()
            end
          end, { 'i', 's' }),
          ['<C-p>'] = cmp.mapping(function(fallback)
            if luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm { select = true },
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif has_words_before() then
              cmp.complete()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end, { 'i', 's' }),
        },
        autocomplete = false,
        formatting = {
          format = lspkind.cmp_format {
            with_text = true,
            menu = {
              otter = '[🦦]',
              nvim_lsp = '[LSP]',
              luasnip = '[snip]',
              buffer = '[buf]',
              path = '[path]',
              spell = '[spell]',
              pandoc_references = '[ref]',
              tags = '[tag]',
              treesitter = '[TS]',
              calc = '[calc]',
              latex_symbols = '[tex]',
              emoji = '[emoji]',
            },
          },
        },
        sources = {
          { name = 'otter' },
          { name = 'path' },
          { name = 'nvim_lsp' },
          { name = 'nvim_lsp_signature_help' },
          { name = 'luasnip', keyword_length = 3, max_item_count = 3 },
          { name = 'pandoc_references' },
          { name = 'buffer', keyword_length = 5, max_item_count = 3 },
          { name = 'spell' },
          { name = 'treesitter', keyword_length = 5, max_item_count = 3 },
          { name = 'calc' },
          { name = 'latex_symbols' },
          { name = 'emoji' },
        },
        view = {
          entries = 'native',
        },
      }
    end,
  },

  -- vim-slime (envio de código para terminal/REPL)
  {
    'jpalardy/vim-slime',
    init = function()
      -- Inicializa variáveis de buffer para todas as linguagens suportadas
      local langs = { 'python', 'r', 'julia', 'bash' }
      for _, lang in ipairs(langs) do
        vim.b['quarto_is_' .. lang .. '_chunk'] = false
      end

      -- Função global para verificar se estamos em um chunk de uma linguagem específica
      _G.Quarto_is_in_lang_chunk = function(lang) return require('otter.tools.functions').is_otter_language_context(lang) end

      -- Configuração do slime (compatível com tmux/neovim)
      vim.g.slime_target = 'tmux'
      vim.g.slime_bracketed_paste = 1
      vim.g.slime_default_config = { socket_name = 'default', target_pane = '.2' }
      vim.g.slime_dispatch_ipython_pause = 100
      vim.b.slime_cell_delimiter = '# %%'

      -- Função de escape personalizada para Quarto (substitui a Vim script)
      _G.SlimeOverride_EscapeText_quarto = function(text)
        local is_python = _G.Quarto_is_in_lang_chunk 'python'
        local is_r = _G.Quarto_is_in_lang_chunk 'r'
        local lines = vim.split(text, '\n')

        -- Python: usar %cpaste para múltiplas linhas
        if is_python and vim.g.slime_python_ipython == 1 and #lines > 1 then
          return { '%cpaste -q\n', vim.g.slime_dispatch_ipython_pause, text, '--\n' }
        -- R: se estiver no modo browser(), precisa de tratamento especial
        elseif is_r and #lines > 1 then
          -- Se detectar que está em modo debug (browser), pode adaptar aqui
          return text
        else
          return text
        end
      end

      -- Registrar a função no Vim para ser usada pela slime
      vim.fn['SlimeOverride_EscapeText_quarto'] = function(text) return _G.SlimeOverride_EscapeText_quarto(text) end

      -- Funções auxiliares para marcar/definir terminal
      local function mark_terminal()
        vim.g.slime_last_channel = vim.b.terminal_job_id
        vim.print('Terminal marcado: ' .. vim.g.slime_last_channel)
      end

      local function set_terminal()
        vim.b.slime_config = { jobid = vim.g.slime_last_channel }
        vim.print 'Terminal definido para o buffer atual'
      end

      local function toggle_slime_tmux_nvim()
        if vim.g.slime_target == 'tmux' then
          vim.g.slime_target = 'neovim'
          vim.g.slime_bracketed_paste = 0
          vim.g.slime_python_ipython = 1
          vim.print 'Alternado para terminal Neovim'
        else
          vim.g.slime_target = 'tmux'
          vim.g.slime_bracketed_paste = 1
          vim.g.slime_default_config = { socket_name = 'default', target_pane = '.2' }
          vim.print 'Alternado para tmux'
        end
      end

      -- Registro de atalhos com which-key (formato moderno)
      local wk = require 'which-key'
      wk.add {
        { '<leader>rm', mark_terminal, desc = 'mark terminal' },
        { '<leader>rs', set_terminal, desc = 'set terminal' },
        { '<leader>rz', toggle_slime_tmux_nvim, desc = 'toggle tmux/nvim terminal' },
      }
    end,
  },

  -- nabla
  {
    'jbyuki/nabla.nvim',
    dependencies = {
      'nvim-neo-tree/neo-tree.nvim',
      'williamboman/mason.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    lazy = true,
    keys = function()
      return {
        -- Mapeamentos individuais
        { '<leader>p', ':lua require("nabla").popup()<cr>', desc = 'NablaPopUp' },
      }
    end,
  },

  -- molten-nvim
  -- {
  --   'benlubas/molten-nvim',
  --   build = ':UpdateRemotePlugins',
  --   init = function()
  --     vim.g.molten_image_provider = 'image.nvim'
  --     vim.g.molten_output_win_max_height = 20
  --     vim.g.molten_auto_open_output = false
  --  end,
  --   keys = {
  --     { '<leader>mi', '<cmd>MoltenInit<cr>', desc = 'molten init' },
  --     { '<leader>mv', ':<C-u>MoltenEvaluateVisual<cr>', mode = 'v', desc = 'molten eval visual' },
  --     { '<leader>mr', '<cmd>MoltenReevaluateCell<cr>', desc = 'molten re-eval cell' },
  --   },
  -- },
}
