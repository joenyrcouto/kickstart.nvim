-- required in which-key plugin spec in plugins/ui.lua as `require 'config.keymap'`
local wk = require 'which-key'
local ms = vim.lsp.protocol.Methods
local map = vim.keymap.set

P = vim.print

vim.g['quarto_is_r_mode'] = nil
vim.g['reticulate_running'] = false

local nmap = function(key, effect, desc) vim.keymap.set('n', key, effect, { silent = true, noremap = true, desc = desc }) end

local vmap = function(key, effect, desc) vim.keymap.set('v', key, effect, { silent = true, noremap = true, desc = desc }) end

local imap = function(key, effect, desc) vim.keymap.set('i', key, effect, { silent = true, noremap = true, desc = desc }) end

local cmap = function(key, effect, desc) vim.keymap.set('c', key, effect, { silent = true, noremap = true, desc = desc }) end

-- Reinicia keys sem sair do nvim
vim.keymap.set('n', '<leader>ks', function()
  local mod = 'config.keymap'
  if package.loaded[mod] then package.loaded[mod] = nil end
  require(mod)
  local win = 0
  local x = vim.api.nvim_win_get_position(win)
  vim.print(x, ' recarregou!')
end, { desc = 'Recarrega o keymap' })

-- Apagar arquivo (dar um kill nele)
map('n', '<C-S-K>', function()
  local file = vim.fn.expand '%:p'
  vim.ui.select({ 'Sim', 'Não' }, {
    prompt = 'Excluir ' .. file .. '?',
  }, function(choice)
    if choice == 'Sim' then
      vim.fn.delete(file)
      vim.cmd 'bd!' -- Fecha o buffer também
      vim.notify('Arquivo excluído.', vim.log.levels.INFO)
    end
  end)
end, { desc = 'Excluir arquivo atual' })

-- select last paste
nmap('gV', '`[v`]')

-- move in command line
cmap('<C-a>', '<Home>')

-- save with ctrl+s
imap('<C-s>', '<esc>:update<cr><esc>')
nmap('<C-s>', '<cmd>:update<cr><esc>')

-- Move between windows using <ctrl> direction
nmap('<C-j>', '<C-W>j')
nmap('<C-k>', '<C-W>k')
nmap('<C-h>', '<C-W>h')
nmap('<C-l>', '<C-W>l')

-- Resize window using <shift> arrow keys
nmap('<S-Up>', '<cmd>resize +2<CR>')
nmap('<S-Down>', '<cmd>resize -2<CR>')
nmap('<S-Left>', '<cmd>vertical resize -2<CR>')
nmap('<S-Right>', '<cmd>vertical resize +2<CR>')

-- Add undo break-points
imap(',', ',<c-g>u')
imap('.', '.<c-g>u')
imap(';', ';<c-g>u')

nmap('Q', '<Nop>')

--- Send code to terminal with vim-slime
--- If an R terminal has been opend, this is in r_mode
--- and will handle python code via reticulate when sent
--- from a python chunk.
--- TODO: incorpoarate this into quarto-nvim plugin
--- such that QuartoSend functions get the same capabilities
--- TODO: figure out bracketed paste for reticulate python repl.
local function send_cell()
  local has_molten, molten_status = pcall(require, 'molten.status')
  local molten_works = false
  local molten_active = ''
  if has_molten then
    molten_works, molten_active = pcall(molten_status.kernels)
  end
  if molten_works and molten_active ~= vim.NIL and molten_active ~= '' then molten_active = molten_status.initialized() end
  if molten_active ~= vim.NIL and molten_active ~= '' and molten_status.kernels() ~= 'Molten' then
    vim.cmd.QuartoSend()
    return
  end

  if vim.b['quarto_is_r_mode'] == nil then
    vim.fn['slime#send_cell']()
    return
  end
  if vim.b['quarto_is_r_mode'] == true then
    vim.g.slime_python_ipython = 0
    local is_python = require('otter.tools.functions').is_otter_language_context 'python'
    if is_python and not vim.b['reticulate_running'] then
      vim.fn['slime#send']('reticulate::repl_python()' .. '\r')
      vim.b['reticulate_running'] = true
    end
    if not is_python and vim.b['reticulate_running'] then
      vim.fn['slime#send']('exit' .. '\r')
      vim.b['reticulate_running'] = false
    end
    vim.fn['slime#send_cell']()
  end
end

--- Send code to terminal with vim-slime
--- If an R terminal has been opend, this is in r_mode
--- and will handle python code via reticulate when sent
--- from a python chunk.
local slime_send_region_cmd = ':<C-u>call slime#send_op(visualmode(), 1)<CR>'
slime_send_region_cmd = vim.api.nvim_replace_termcodes(slime_send_region_cmd, true, false, true)
local function send_region()
  -- if filetyps is not quarto, just send_region
  if vim.bo.filetype ~= 'quarto' or vim.b['quarto_is_r_mode'] == nil then
    vim.cmd('normal' .. slime_send_region_cmd)
    return
  end
  if vim.b['quarto_is_r_mode'] == true then
    vim.g.slime_python_ipython = 0
    local is_python = require('otter.tools.functions').is_otter_language_context 'python'
    if is_python and not vim.b['reticulate_running'] then
      vim.fn['slime#send']('reticulate::repl_python()' .. '\r')
      vim.b['reticulate_running'] = true
    end
    if not is_python and vim.b['reticulate_running'] then
      vim.fn['slime#send']('exit' .. '\r')
      vim.b['reticulate_running'] = false
    end
    vim.cmd('normal' .. slime_send_region_cmd)
  end
end

-- send code with ctrl+Enter
-- just like in e.g. RStudio
-- needs kitty (or other terminal) config:
-- map shift+enter send_text all \x1b[13;2u
-- map ctrl+enter send_text all \x1b[13;5u
nmap('<c-cr>', send_cell)
nmap('<s-cr>', send_cell)
imap('<c-cr>', send_cell)
imap('<s-cr>', send_cell)

--- Show R dataframe in the browser
-- might not use what you think should be your default web browser
-- because it is a plain html file, not a link
-- see https://askubuntu.com/a/864698 for places to look for
local function show_r_table()
  local node = vim.treesitter.get_node { ignore_injections = false }
  assert(node, 'no symbol found under cursor')
  local text = vim.treesitter.get_node_text(node, 0)
  local cmd = [[call slime#send("DT::datatable(]] .. text .. [[)" . "\r")]]
  vim.cmd(cmd)
end

-- keep selection after indent/dedent
vmap('>', '>gv')
vmap('<', '<gv')

-- center after search and jumps
nmap('n', 'nzz')
nmap('<c-d>', '<c-d>zz')
nmap('<c-u>', '<c-u>zz')

-- move between splits and tabs
nmap('<c-h>', '<c-w>h')
nmap('<c-l>', '<c-w>l')
nmap('<c-j>', '<c-w>j')
nmap('<c-k>', '<c-w>k')
nmap('H', '<cmd>tabprevious<cr>')
nmap('L', '<cmd>tabnext<cr>')

local function toggle_light_dark_theme()
  if vim.o.background == 'light' then
    vim.o.background = 'dark'
  else
    vim.o.background = 'light'
  end
end

---Is the current context a code chunk?
---@param lang string language of the code chunk
---@return boolean
local is_code_chunk = function(lang)
  local current = require('otter.keeper').get_current_language_context()
  if current == lang then
    return true
  else
    return false
  end
end

--- Insert code chunk of given language
--- Splits current chunk if already within a chunk
--- @param lang string
--- @param curly boolean
local insert_a_code_chunk = function(lang, curly)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<esc>', true, false, true), 'n', true)
  local keys
  if curly == nil then curly = true end
  if is_code_chunk(lang) then
    if curly then
      keys = [[o```<cr><cr>```{]] .. lang .. [[}<esc>o]]
    else
      keys = [[o```<cr><cr>```]] .. lang .. [[<esc>o]]
    end
  else
    if curly then
      keys = [[o```{]] .. lang .. [[}<cr>```<esc>O]]
    else
      keys = [[o```]] .. lang .. [[<cr>```<esc>O]]
    end
  end
  keys = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', false)
end

local insert_code_chunk = function(lang) insert_a_code_chunk(lang, true) end

local insert_plain_code_chunk = function(lang) insert_a_code_chunk(lang, false) end

local insert_r_chunk = function() insert_code_chunk 'r' end

local insert_py_chunk = function() insert_code_chunk 'python' end

local insert_lua_chunk = function() insert_code_chunk 'lua' end

local insert_julia_chunk = function() insert_code_chunk 'julia' end

local insert_bash_chunk = function() insert_code_chunk 'bash' end

local insert_ojs_chunk = function() insert_code_chunk 'ojs' end

local insert_plain_r_chunk = function() insert_plain_code_chunk 'r' end

local insert_plain_py_chunk = function() insert_plain_code_chunk 'python' end

local insert_plain_lua_chunk = function() insert_plain_code_chunk 'lua' end

local insert_plain_julia_chunk = function() insert_plain_code_chunk 'julia' end

local insert_plain_bash_chunk = function() insert_plain_code_chunk 'bash' end

local insert_plain_ojs_chunk = function() insert_plain_code_chunk 'ojs' end

--show kepbindings with whichkey
--add your own here if you want them to
--show up in the popup as well

-- normal mode
wk.add({
  { '<c-LeftMouse>', '<cmd>lua vim.lsp.buf.definition()<CR>', desc = 'go to definition' },
  { '<c-q>', '<cmd>q<cr>', desc = 'close buffer' },
  { '<cm-i>', insert_py_chunk, desc = 'python code chunk' },
  { '<esc>', '<cmd>noh<cr>', desc = 'remove search highlight' },
  { '<m-I>', insert_py_chunk, desc = 'python code chunk' },
  { '<m-i>', insert_r_chunk, desc = 'r code chunk' },
  { '[q', ':silent cprev<cr>', desc = '[q]uickfix prev' },
  { ']q', ':silent cnext<cr>', desc = '[q]uickfix next' },
  { 'gN', 'Nzzzv', desc = 'center search' },
  { 'gf', ':e <cfile><CR>', desc = 'edit file' },
  { 'gl', '<c-]>', desc = 'open help link' },
  { 'n', 'nzzzv', desc = 'center search' },
  { 'z?', ':setlocal spell!<cr>', desc = 'toggle [z]pellcheck' },
  { 'zl', ':Telescope spell_suggest<cr>', desc = '[l]ist spelling suggestions' },
}, { mode = 'n', silent = true })

-- visual mode
wk.add {
  {
    mode = { 'v' },
    { '.', ':norm .<cr>', desc = 'repat last normal mode command' },
    { '<M-j>', ":m'>+<cr>`<my`>mzgv`yo`z", desc = 'move line down' },
    { '<M-k>', ":m'<-2<cr>`>my`<mzgv`yo`z", desc = 'move line up' },
    { '<cr>', send_region, desc = 'run code region' },
    { 'q', ':norm @q<cr>', desc = 'repat q macro' },
  },
}

-- visual with <leader>
wk.add({
  { '<leader>d', '"_d', desc = 'delete without overwriting reg', mode = 'v' },
  { '<leader>p', '"_dP', desc = 'replace without overwriting reg', mode = 'v' },
}, { mode = 'v' })

-- insert mode
wk.add({
  {
    mode = { 'i' },
    { '<c-x><c-x>', '<c-x><c-o>', desc = 'omnifunc completion' },
    { '<cm-i>', insert_py_chunk, desc = 'python code chunk' },
    { '<m-->', ' <- ', desc = 'assign' },
    { '<m-I>', insert_py_chunk, desc = 'python code chunk' },
    { '<m-i>', insert_r_chunk, desc = 'r code chunk' },
    { '<m-m>', ' |>', desc = 'pipe' },
  },
}, { mode = 'i' })

local function new_terminal(lang) vim.cmd('vsplit term://' .. lang) end

local function new_terminal_python() new_terminal 'python' end

local function new_terminal_r() new_terminal 'R --no-save' end

local function new_terminal_ipython() new_terminal 'ipython --no-confirm-exit --no-autoindent' end

local function new_terminal_julia() new_terminal 'julia' end

local function new_terminal_shell() new_terminal '$SHELL' end

local function get_otter_symbols_lang()
  local otterkeeper = require 'otter.keeper'
  local main_nr = vim.api.nvim_get_current_buf()
  local langs = {}
  for i, l in ipairs(otterkeeper.rafts[main_nr].languages) do
    langs[i] = i .. ': ' .. l
  end
  -- promt to choose one of langs
  local i = vim.fn.inputlist(langs)
  local lang = otterkeeper.rafts[main_nr].languages[i]
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(),
    otter = {
      lang = lang,
    },
  }
  -- don't pass a handler, as we want otter to use it's own handlers
  vim.lsp.buf_request(main_nr, ms.textDocument_documentSymbol, params, nil)
end

vim.keymap.set('n', '<leader>os', get_otter_symbols_lang, { desc = 'otter [s]ymbols' })

local function toggle_conceal()
  local lvl = vim.o.conceallevel
  if lvl > DefaultConcealLevel then
    vim.o.conceallevel = DefaultConcealLevel
  else
    vim.o.conceallevel = FullConcealLevel
  end
end

--- Clear image cache for snacks.nvim
--- Remove the ~/.cache/nvim/snacks/image directory
local function clear_image_cache()
  local cache_dir = vim.fn.stdpath 'cache' .. '/snacks/image'
  if vim.fn.isdirectory(cache_dir) == 1 then vim.fn.delete(cache_dir, 'rf') end
end

-- eval "$(tmux showenv -s DISPLAY)"
-- normal mode with <leader>
wk.add({
  {
    { '<leader><cr>', send_cell, desc = 'run code cell' },
    { '<leader>c', group = '[c]ode / [c]ell / [c]hunk' },
    { '<leader>cj', new_terminal_julia, desc = 'new [j]ulia terminal' },
    { '<leader>cn', new_terminal_shell, desc = '[n]ew terminal with shell' },
    { '<leader>cp', new_terminal_python, desc = 'new [p]ython terminal' },
    { '<leader>cr', new_terminal_r, desc = 'new [R] terminal' },
    { '<leader>d', group = '[d]ebug' },
    { '<leader>dt', group = '[t]est' },
    { '<leader>e', group = '[e]dit' },
    { '<leader>e', group = '[t]mux' },
    { '<leader>fd', [[eval "$(tmux showenv -s DISPLAY)"]], desc = '[d]isplay fix' },
    { '<leader>f', group = '[f]ind (telescope)' },
    { '<leader>f<space>', '<cmd>Telescope buffers<cr>', desc = '[ ] buffers' },
    { '<leader>fM', '<cmd>Telescope man_pages<cr>', desc = '[M]an pages' },
    { '<leader>fb', '<cmd>Telescope current_buffer_fuzzy_find<cr>', desc = '[b]uffer fuzzy find' },
    { '<leader>fc', '<cmd>Telescope git_commits<cr>', desc = 'git [c]ommits' },
    { '<leader>fd', '<cmd>Telescope buffers<cr>', desc = '[d] buffers' },
    { '<leader>ff', '<cmd>Telescope find_files<cr>', desc = '[f]iles' },
    { '<leader>fg', '<cmd>Telescope live_grep<cr>', desc = '[g]rep' },
    { '<leader>fh', '<cmd>Telescope help_tags<cr>', desc = '[h]elp' },
    { '<leader>fj', '<cmd>Telescope jumplist<cr>', desc = '[j]umplist' },
    { '<leader>fk', '<cmd>Telescope keymaps<cr>', desc = '[k]eymaps' },
    { '<leader>fl', '<cmd>Telescope loclist<cr>', desc = '[l]oclist' },
    { '<leader>fm', '<cmd>Telescope marks<cr>', desc = '[m]arks' },
    { '<leader>fq', '<cmd>Telescope quickfix<cr>', desc = '[q]uickfix' },
    { '<leader>g', group = '[g]it' },
    { '<leader>gb', group = '[b]lame' },
    { '<leader>gbb', ':GitBlameToggle<cr>', desc = '[b]lame toggle virtual text' },
    { '<leader>gbc', ':GitBlameCopyCommitURL<cr>', desc = '[c]opy' },
    { '<leader>gbo', ':GitBlameOpenCommitURL<cr>', desc = '[o]pen' },
    { '<leader>gc', ':GitConflictRefresh<cr>', desc = '[c]onflict' },
    { '<leader>gd', group = '[d]iff' },
    { '<leader>gs', ':Gitsigns<cr>', desc = 'git [s]igns' },
    {
      '<leader>gwc',
      ":lua require('telescope').extensions.git_worktree.create_git_worktree()<cr>",
      desc = 'worktree create',
    },
    {
      '<leader>gws',
      ":lua require('telescope').extensions.git_worktree.git_worktrees()<cr>",
      desc = 'worktree switch',
    },
    { '<leader>h', group = '[h]elp / [h]ide / debug' },
    { '<leader>hc', group = '[c]onceal' },
    { '<leader>hc', toggle_conceal, desc = '[c]onceal toggle' },
    { '<leader>ht', group = '[t]reesitter' },
    { '<leader>htt', vim.treesitter.inspect_tree, desc = 'show [t]ree' },
    { '<leader>i', group = '[i]mage/[i]nsert' },
    { '<leader>ic', clear_image_cache, desc = '[c]lear image cache' },
    { '<leader>l', group = '[l]anguage/lsp' },
    { '<leader>ld', group = '[d]iagnostics' },
    {
      '<leader>ldd',
      function() vim.diagnostic.enable(false) end,
      desc = '[d]isable',
    },
    { '<leader>lde', vim.diagnostic.enable, desc = '[e]nable' },
    { '<leader>le', vim.diagnostic.open_float, desc = 'diagnostics (show hover [e]rror)' },
    { '<leader>lg', ':Neogen<cr>', desc = 'neo[g]en docstring' },
    { '<leader>o', group = '[o]tter & c[o]de' },
    { '<leader>oa', require('otter').activate, desc = 'otter [a]ctivate' },
    { '<leader>oc', 'O# %%<cr>', desc = 'magic [c]omment code chunk # %%' },
    { '<leader>od', require('otter').activate, desc = 'otter [d]eactivate' },

    { '<leader>oj', insert_julia_chunk, desc = '[j]ulia code chunk' },
    { '<leader>ol', insert_lua_chunk, desc = '[l]lua code chunk' },
    { '<leader>oo', insert_ojs_chunk, desc = '[o]bservable js code chunk' },
    { '<leader>op', insert_py_chunk, desc = '[p]ython code chunk' },
    { '<leader>or', insert_r_chunk, desc = '[r] code chunk' },
    { '<leader>ob', insert_bash_chunk, desc = '[b]ash code chunk' },

    { '<leader>Oj', insert_plain_julia_chunk, desc = '[j]ulia code chunk' },
    { '<leader>Ol', insert_plain_lua_chunk, desc = '[l]lua code chunk' },
    { '<leader>Oo', insert_plain_ojs_chunk, desc = '[o]bservable js code chunk' },
    { '<leader>Op', insert_plain_py_chunk, desc = '[p]ython code chunk' },
    { '<leader>Or', insert_plain_r_chunk, desc = '[r] code chunk' },
    { '<leader>Ob', insert_plain_bash_chunk, desc = '[b]ash code chunk' },

    { '<leader>q', group = '[q]uarto' },
    {
      '<leader>qE',
      function() require('otter').export(true) end,
      desc = '[E]xport with overwrite',
    },
    { '<leader>qa', ':QuartoActivate<cr>', desc = '[a]ctivate' },
    { '<leader>qe', require('otter').export, desc = '[e]xport' },
    { '<leader>qh', ':QuartoHelp ', desc = '[h]elp' },
    { '<leader>qp', ":lua require'quarto'.quartoPreview()<cr>", desc = '[p]review' },
    { '<leader>qu', ":lua require'quarto'.quartoUpdatePreview()<cr>", desc = '[u]pdate preview' },
    { '<leader>qq', ":lua require'quarto'.quartoClosePreview()<cr>", desc = '[q]uiet preview' },
    { '<leader>qr', group = '[r]un' },
    { '<leader>qra', ':QuartoSendAll<cr>', desc = 'run [a]ll' },
    { '<leader>qrb', ':QuartoSendBelow<cr>', desc = 'run [b]elow' },
    { '<leader>qrr', ':QuartoSendAbove<cr>', desc = 'to cu[r]sor' },
    { '<leader>r', group = '[r] R specific tools' },
    { '<leader>rt', show_r_table, desc = 'show [t]able' },
    { '<leader>v', group = '[v]im' },
    { '<leader>vc', ':Telescope colorscheme<cr>', desc = '[c]olortheme' },
    { '<leader>vh', ':execute "h " . expand("<cword>")<cr>', desc = 'vim [h]elp for current word' },
    { '<leader>vl', ':Lazy<cr>', desc = '[l]azy package manager' },
    { '<leader>vm', ':Mason<cr>', desc = '[m]ason software installer' },
    { '<leader>vs', ':e $MYVIMRC | :cd %:p:h | split . | wincmd k<cr>', desc = '[s]ettings, edit vimrc' },
    { '<leader>vt', toggle_light_dark_theme, desc = '[t]oggle light/dark theme' },
    { '<leader>x', group = 'e[x]ecute' },
    { '<leader>xx', ':w<cr>:source %<cr>', desc = '[x] source %' },
  },
}, { mode = 'n' })

-- [ CODECOMPANION ]
-- Menu de Ações (Principal para diagnósticos e correções)
map({ 'n', 'v' }, '<leader>ca', '<cmd>CodeCompanionActions<cr>', { desc = 'CodeCompanion: Ações' })
-- Chat Interativo (Para discussões teóricas e lógica)
map({ 'n', 'v' }, '<leader>cc', '<cmd>CodeCompanionChat Toggle<cr>', { desc = 'CodeCompanion: Alternar Chat' })
-- Inserção Inline (O "Copilot" sob demanda para criar código)
map({ 'n', 'v' }, '<leader>ci', '<cmd>CodeCompanion<cr>', { desc = 'CodeCompanion: Prompt Inline' })
-- Adicionar código ao Chat (Sem sair do buffer atual)
map('v', 'ga', '<cmd>CodeCompanionChat Add<cr>', { desc = 'CodeCompanion: Adicionar ao Chat' })

-- [ NAVEGAÇÃO ENTRE JANELAS ]
map('n', '<C-h>', '<C-w>h', { desc = 'Janela à esquerda' })
map('n', '<C-j>', '<C-w>j', { desc = 'Janela abaixo' })
map('n', '<C-k>', '<C-w>k', { desc = 'Janela acima' })
map('n', '<C-l>', '<C-w>l', { desc = 'Janela à direita' })

-- [ RENOMEAR O ARQUIVO ATUAL NO DISCO ]
map('n', '<leader>rn', function()
  local old_name = vim.api.nvim_buf_get_name(0)
  if old_name == '' then return print 'Erro: Arquivo não salvo no disco' end

  local new_name = vim.fn.input('Novo nome do arquivo: ', old_name, 'file')

  if new_name ~= '' and new_name ~= old_name then
    local uv = vim.uv or vim.loop
    local ok, err = uv.fs_rename(old_name, new_name)

    if ok then
      vim.cmd('edit ' .. vim.fn.fnameescape(new_name))
      vim.cmd('bwipeout ' .. vim.fn.fnameescape(old_name))
      print('\nArquivo renomeado para: ' .. new_name)
    else
      print('\nErro ao renomear: ' .. err)
    end
  end
end, { desc = 'Renomear arquivo físico' })

-- [ NAVEGAÇÃO DE BUSCA E LIMPEZA MANUAL ]
local function toggle_search_clean()
  if vim.v.hlsearch == 1 then
    vim.cmd 'nohlsearch'
    vim.api.nvim_command "echo ''"
    vim.cmd 'redraw'
  else
    local last_search = vim.fn.getreg '/'
    if last_search ~= '' then
      vim.opt.hlsearch = true
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('nN', true, false, true), 'n', true)
    end
  end
end

-- Mapeamento do '?' (Substitui a busca reversa nativa)
map('n', '?', toggle_search_clean, {
  desc = 'Toggle Search e Limpar Terminal',
  silent = true,
  nowait = true,
})

-- [ SALVAMENTO E FECHAMENTO ]
map('n', '<leader>w', '<cmd>w<cr>', { desc = 'salvar arquivo' })
map('n', '<leader>q', '<cmd>confirm q<cr>', { desc = 'fechar janela atual' })
map('n', '<leader><esc>', '<cmd>qa!<cr>', { desc = 'sair do neovim forçadamente' })

-- [ NAVEGAÇÃO ENTRE ABAS (BUFFERS - NVCHAD) ]
map('n', '<Tab>', function() require('nvchad.tabufline').next() end, { desc = 'Próxima Aba' })
map('n', '<S-Tab>', function() require('nvchad.tabufline').prev() end, { desc = 'Aba Anterior' })
map('n', '<leader>x', function() require('nvchad.tabufline').close_buffer() end, { desc = 'Fechar Aba' })

-- [ DIVISÃO DE TELA (SPLITS) ]
map('n', '<leader>v', '<cmd>vsp<cr>', { desc = 'Dividir Verticalmente' })
map('n', '<leader>h', '<cmd>sp<cr>', { desc = 'Dividir Horizontalmente' })

-- [ TERMINAIS NVCHAD ]
map({ 'n', 't' }, '<A-h>', function() require('nvchad.term').toggle { pos = 'sp', id = 'htoggle' } end)
map({ 'n', 't' }, '<A-i>', function() require('nvchad.term').toggle { pos = 'float', id = 'floatTerm' } end)

-------------------------------------------------------------------
-- [ CONFIGURAÇÕES ESPECÍFICAS DO OBSIDIAN ]
-------------------------------------------------------------------

-- Tecla ENTER: Seguir Link
map('n', '<CR>', function()
  local ok, obsidian = pcall(require, 'obsidian')
  if ok then
    -- Tenta seguir o link; se falhar, usa o comportamento normal do <CR>
    local success = pcall(vim.cmd, 'ObsidianFollowLink')
    if success then return '' end
  end
  return '<CR>'
end, { expr = true, desc = 'Obsidian: Seguir Link' })

-- Tecla Espaço + Shift + R: Renomear Inteligente
map('n', '<leader>R', function()
  if vim.bo.filetype == 'markdown' or vim.bo.filetype == 'quarto' then
    vim.cmd 'ObsidianRename'
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<leader>rn', true, false, true), 'm', true)
  end
end, { desc = 'Renomear Inteligente' })

map('n', '<leader>oi', '<cmd>ObsidianPasteImg<CR>', { desc = 'Colar Imagem' })
map('n', '<leader>ob', '<cmd>ObsidianBacklinks<CR>', { desc = 'Ver Backlinks' })

-- ==========================================
-- INTEGRAÇÃO GIT-BUG (ATUALIZADA - BRIDGE AUTH)
-- ==========================================

-- ---------- Funções auxiliares ----------

local function adopt_identity_in_repo(git_root, id)
  local cmd = string.format('cd %s && git bug user adopt %s', vim.fn.shellescape(git_root), id)
  local ok = os.execute(cmd .. ' > /dev/null 2>&1')
  return ok == 0
end

local function get_working_dir()
  local bufpath = vim.api.nvim_buf_get_name(0)
  if bufpath ~= '' then
    return vim.fn.fnamemodify(bufpath, ':p:h')
  else
    return vim.fn.getcwd()
  end
end

local function get_git_root(cwd)
  local output = vim.fn.system('cd ' .. vim.fn.shellescape(cwd) .. ' && git rev-parse --show-toplevel 2>/dev/null')
  if vim.v.shell_error ~= 0 then return nil end
  return output:gsub('%s+', '')
end

local function kitty_remote_available() return os.execute 'kitty @ ls > /dev/null 2>&1' end

local function clean_locks(git_root)
  os.execute('cd ' .. vim.fn.shellescape(git_root) .. ' && rm -f .git/refs/bugs/lock .git/refs/bugs.lock .git/git-bug.lock 2>/dev/null')
end

local function kitty_float_exec(cmd, git_root)
  if not kitty_remote_available() then return false end
  local script_path = vim.fn.stdpath 'cache' .. '/kitty_gitbug.sh'
  local script_content = string.format(
    [[
#!/bin/bash
cd %s
export EDITOR=nvim
%s
]],
    vim.fn.shellescape(git_root),
    cmd
  )
  local file = io.open(script_path, 'w')
  if not file then return false end
  file:write(script_content)
  file:close()
  os.execute('chmod +x ' .. script_path)
  local kitty_cmd = string.format(
    'kitty @ launch --type=overlay --title "Git Bug" bash -c %s 2>/dev/null || ' .. 'kitty @ launch --type=window --title "Git Bug" bash -c %s',
    vim.fn.shellescape(script_path),
    vim.fn.shellescape(script_path)
  )
  return os.execute(kitty_cmd) == 0
end

local function nvim_term_exec(cmd, git_root, interactive, wait_after)
  clean_locks(git_root)
  local prefix = 'cd ' .. vim.fn.shellescape(git_root) .. ' && clear; '
  local suffix = wait_after and "; echo; echo '--- PROCESSO CONCLUÍDO. PRESSIONE ENTER PARA SAIR ---'; read" or '; exit'
  local full_cmd = prefix .. cmd .. suffix
  vim.cmd('split | terminal bash -c ' .. vim.fn.shellescape(full_cmd))
  if interactive then vim.cmd 'startinsert' end
end

-- ---------- IDENTIDADES ----------

local function get_local_identities(git_root)
  local output = vim.fn.system('cd ' .. vim.fn.shellescape(git_root) .. ' && git bug user show 2>/dev/null')
  if vim.v.shell_error ~= 0 then return {}, nil end
  local identities = {}
  local active_short = nil
  for line in output:gmatch '[^\r\n]+' do
    local short_id, name = line:match '^([%x]+)%s+(.+)$'
    if short_id and name then table.insert(identities, { short_id = short_id, name = name }) end
    if not active_short then active_short = short_id end
  end
  return identities, active_short
end

local function create_local_identity(git_root)
  local cmd = 'cd ' .. vim.fn.shellescape(git_root) .. ' && export EDITOR=nvim; git bug user new'
  vim.cmd('split | terminal bash -c "' .. cmd .. "; echo; echo '--- PROCESSO CONCLUÍDO. PRESSIONE ENTER PARA SAIR ---'; read\"")
end

-- Exclui uma identidade local usando o short_id e wildcard (*)
local function delete_local_identity(git_root, short_id)
  local id_pattern = vim.fn.shellescape(git_root .. '/.git/refs/identities/' .. short_id) .. '*'
  -- Correção: apontamento restrito ao arquivo de identidades no cache
  local cache_filepath = vim.fn.shellescape(git_root .. '/.git/git-bug/cache/identities')
  local ok = os.execute('rm -rf ' .. id_pattern .. ' 2>/dev/null')
  os.execute('rm -f ' .. cache_filepath .. ' 2>/dev/null')
  os.execute('mkdir -p' .. git_root .. '.git/git-bug/cache/')
  return ok == 0
end

local function ensure_repo_has_identity(git_root)
  local locals, _ = get_local_identities(git_root)
  if #locals > 0 then return true end

  vim.notify('Nenhuma identidade local encontrada. Por favor, crie uma identidade antes de prosseguir.', vim.log.levels.WARN)
  return false
end

-- ---------- BRIDGE (USANDO bridge auth) ----------
local function has_github_bridge(git_root)
  local output = vim.fn.system('cd ' .. vim.fn.shellescape(git_root) .. ' && git bug bridge auth 2>/dev/null')
  -- Se a saída contiver "github", significa que já existe uma autenticação para GitHub
  return output:match 'github' ~= nil
end

local function auto_configure_bridge(git_root)
  if has_github_bridge(git_root) then
    vim.notify('Git Bug: Autenticação GitHub já configurada.', vim.log.levels.INFO)
    return true
  end

  local token = vim.fn.system('gh auth token 2>/dev/null'):gsub('%s+', '')
  if token == '' then
    vim.notify('Git Bug: Token do gh não encontrado. Execute "gh auth login".', vim.log.levels.WARN)
    return false
  end

  local repo_url = vim.fn.system('cd ' .. vim.fn.shellescape(git_root) .. ' && git remote get-url origin 2>/dev/null'):gsub('%s+', '')
  local owner, project = repo_url:match 'github.com[:/]([^/]+)/([^/]+)%.git$'
  if not owner then
    owner, project = repo_url:match 'github.com[:/]([^/]+)/(.+)$'
  end
  if not owner or not project then
    vim.notify('Git Bug: Não foi possível extrair owner/project do remote origin.', vim.log.levels.WARN)
    return false
  end

  -- Monta o comando com os parâmetros conhecidos, mas sem --non-interactive para permitir escolha
  local cmd = string.format(
    'cd %s && git bug bridge new --name github --target github --owner %s --project %s --token %s',
    vim.fn.shellescape(git_root),
    owner,
    project,
    token
  )

  -- Abre um terminal split para que o usuário possa ver o log e fazer escolhas interativas
  vim.cmd('split | terminal bash -c "' .. cmd .. "; echo; echo '--- PROCESSO CONCLUÍDO. PRESSIONE ENTER PARA SAIR ---'; read\"")
  vim.cmd 'startinsert'

  -- Nota: não podemos verificar o sucesso imediatamente porque o terminal é assíncrono.
  -- Mas após o usuário finalizar, a bridge estará configurada.
  return true
end
-- ---------- EXECUTOR ----------
local function gitbug_exec(cmd, git_root, interactive, wait_after, use_kitty)
  if not ensure_repo_has_identity(git_root) then return end
  clean_locks(git_root)

  if cmd:match 'bridge pull' or cmd:match 'bridge push' then
    if not auto_configure_bridge(git_root) then
      vim.notify('Sincronização cancelada: autenticação GitHub não configurada.', vim.log.levels.WARN)
      return
    end
  end

  if use_kitty then
    if not kitty_float_exec(cmd, git_root) then
      vim.notify('Kitty remote indisponível, abrindo no terminal integrado...', vim.log.levels.WARN)
      nvim_term_exec(cmd, git_root, interactive, wait_after)
    end
  else
    nvim_term_exec(cmd, git_root, interactive, wait_after)
  end
end

-- =============================================================================
-- MENU DE IDENTIDADES (<leader>gu)
-- =============================================================================
vim.keymap.set('n', '<leader>gu', function()
  local cwd = get_working_dir()
  local git_root = get_git_root(cwd)

  if not git_root then
    vim.notify('Você não está em um repositório Git.', vim.log.levels.ERROR)
    return
  end

  local locals, active_short = get_local_identities(git_root)
  local items = {}

  if active_short then
    local active_name = nil
    for _, ident in ipairs(locals) do
      if ident.short_id == active_short then
        active_name = ident.name
        break
      end
    end
    table.insert(items, {
      display = string.format('⭐ Ativa: %s (%s…)', active_name or 'desconhecida', active_short),
      action = 'header',
    })
  else
    table.insert(items, { display = '⚠️ Nenhuma identidade ativa', action = 'header' })
  end
  table.insert(items, { display = '---', action = 'separator' })

  table.insert(items, { display = '📂 IDENTIDADES LOCAIS', action = 'header' })
  for _, ident in ipairs(locals) do
    local marker = (active_short == ident.short_id) and '✓' or ' '
    table.insert(items, {
      display = string.format('  %s %s (%s…)', marker, ident.name, ident.short_id),
      short_id = ident.short_id,
      action = 'use_local',
    })
  end
  table.insert(items, { display = '[+] Criar nova identidade local', action = 'create_local' })
  if #locals > 0 then table.insert(items, { display = '[✕] Excluir uma identidade local...', action = 'delete_local_menu' }) end

  vim.ui.select(items, {
    prompt = 'Gerenciar identidades Git-Bug',
    format_item = function(item) return item.display end,
  }, function(choice)
    if not choice then return end

    if choice.action == 'create_local' then
      create_local_identity(git_root)
    elseif choice.action == 'delete_local_menu' then
      local del_items = {}
      for _, ident in ipairs(locals) do
        table.insert(del_items, {
          display = string.format('%s (%s…)', ident.name, ident.short_id),
          short_id = ident.short_id,
        })
      end
      vim.ui.select(del_items, {
        prompt = 'Escolha a identidade LOCAL para excluir:',
        format_item = function(item) return item.display end,
      }, function(del_choice)
        if not del_choice then return end
        vim.ui.select({ 'Sim', 'Não' }, {
          prompt = string.format('Confirmar exclusão LOCAL de %s?', del_choice.display),
        }, function(confirm)
          if confirm == 'Sim' then
            if delete_local_identity(git_root, del_choice.short_id) then
              if active_short == del_choice.short_id then
                local remaining = {}
                for _, ident in ipairs(locals) do
                  if ident.short_id ~= del_choice.short_id then table.insert(remaining, ident) end
                end
                if #remaining > 0 then
                  adopt_identity_in_repo(git_root, remaining[1].short_id)
                  vim.notify('Identidade local removida. Nova ativa: ' .. remaining[1].name, vim.log.levels.INFO)
                else
                  vim.notify('Identidade local removida. Nenhuma outra local disponível.', vim.log.levels.WARN)
                end
              else
                vim.notify('Identidade local removida.', vim.log.levels.INFO)
              end
            else
              vim.notify('Falha ao remover identidade local.', vim.log.levels.ERROR)
            end
          end
        end)
      end)
    elseif choice.action == 'use_local' then
      vim.ui.select({ 'Sim', 'Não' }, {
        prompt = string.format 'Tornar esta a identidade ativa?',
      }, function(confirm)
        if confirm == 'Sim' then
          if adopt_identity_in_repo(git_root, choice.short_id) then
            vim.notify('Identidade ativa alterada com sucesso!', vim.log.levels.INFO)
          else
            vim.notify('Falha ao alterar identidade.', vim.log.levels.ERROR)
          end
        end
      end)
    end
  end)
end, { desc = 'Git Bug: Gerenciar identidades' })

-- =============================================================================
-- DEMAIS ATALHOS
-- =============================================================================

-- Configurar remote do GitHub e sincronizar (mixed reset)
vim.keymap.set('n', '<leader>gr', function()
  local cwd = get_working_dir()
  local git_root = get_git_root(cwd)

  if not git_root then
    vim.ui.select({ 'Sim', 'Não' }, {
      prompt = 'Você não está em um repositório Git. Deseja inicializar um agora?',
    }, function(choice)
      if choice == 'Sim' then
        local init_cmd = 'cd ' .. vim.fn.shellescape(cwd) .. ' && git init'
        nvim_term_exec(init_cmd, cwd, false, true)
        vim.notify('Repositório Git inicializado. Execute <leader>gr novamente.', vim.log.levels.INFO)
      end
    end)
    return
  end

  if vim.fn.executable 'gh' ~= 1 then
    vim.notify('GitHub CLI (gh) não está instalado.\nInstale com: sudo pacman -S github-cli (Arch) ou https://cli.github.com', vim.log.levels.ERROR)
    return
  end

  local auth_status = vim.fn.system 'gh auth status 2>&1'
  if auth_status:match 'not logged in' or auth_status:match 'Você não está logado' then
    vim.ui.select({ 'Sim', 'Não' }, {
      prompt = 'Você não está autenticado no GitHub CLI. Deseja fazer login agora?',
    }, function(choice)
      if choice == 'Sim' then vim.cmd 'split | terminal gh auth login' end
    end)
    return
  end

  local username = vim.fn.system('gh api user --jq .login 2>/dev/null'):gsub('%s+', '')
  if username == '' then
    vim.notify('Não foi possível obter seu username do GitHub. Verifique sua autenticação com "gh auth status".', vim.log.levels.ERROR)
    return
  end

  local folder_name = vim.fn.fnamemodify(git_root, ':t')
  local repo_name = vim.fn.input('Nome do repositório no GitHub: ', folder_name)
  if repo_name == '' then
    vim.notify('Nome do repositório é obrigatório.', vim.log.levels.WARN)
    return
  end

  local existing_remote = vim.fn.system('cd ' .. vim.fn.shellescape(git_root) .. ' && git remote get-url origin 2>/dev/null'):gsub('%s+', '')
  local remote_url = 'https://github.com/' .. username .. '/' .. repo_name .. '.git'

  local cmd = string.format('cd %s && ', vim.fn.shellescape(git_root))
  if existing_remote ~= '' then
    vim.ui.select({ 'Sim, substituir', 'Não, cancelar' }, {
      prompt = string.format('Remote origin já existe (%s). Deseja substituí-lo por %s?', existing_remote, remote_url),
    }, function(choice)
      if choice == 'Sim, substituir' then
        local update_cmd = cmd .. string.format('git remote set-url origin %s; git fetch origin; git reset --mixed origin/master', remote_url)
        nvim_term_exec(update_cmd, git_root, false, true)
        vim.notify('Remote atualizado e sincronizado com origin/master.', vim.log.levels.INFO)
      end
    end)
  else
    local add_cmd = cmd .. string.format('git remote add origin %s; git fetch origin; git reset --mixed origin/master', remote_url)
    nvim_term_exec(add_cmd, git_root, false, true)
    vim.notify('Remote configurado e sincronizado com origin/master.', vim.log.levels.INFO)
  end
end, { desc = 'Git: Configurar remote (mixed reset)' })

-- Inicializar repositório (não requer identidade)
vim.keymap.set('n', '<leader>gi', function()
  local cwd = get_working_dir()
  local git_root = get_git_root(cwd)
  if not git_root then
    vim.notify('Fora de um repositório Git.', vim.log.levels.ERROR)
    return
  end
  local cmd = 'cd ' .. vim.fn.shellescape(git_root) .. ' && git init'
  nvim_term_exec(cmd, git_root, false, true)
end, { desc = 'Git: Init' })

vim.keymap.set('n', '<leader>gl', function()
  local cwd = get_working_dir()
  local git_root = get_git_root(cwd)

  if not git_root then
    vim.notify('Fora de um repositório Git.', vim.log.levels.ERROR)
    return
  end

  local locals, active_short = get_local_identities(git_root)
  if #locals == 0 then
    vim.notify(
      '👋 Parece que você ainda não tem um perfil de usuário neste repositório! Crie um em "<leader>gu" para acessar a interface.',
      vim.log.levels.INFO
    )
    return
  end

  -- Fallback: auto-adota a primeira identidade se o ambiente perdeu a referência
  if not active_short then adopt_identity_in_repo(git_root, locals[1].short_id) end

  clean_locks(git_root)

  if not kitty_float_exec('git bug termui', git_root) then
    vim.notify('Kitty remote indisponível, abrindo no terminal integrado...', vim.log.levels.WARN)
    nvim_term_exec('git bug termui', git_root, true, false)
  end
end, { desc = 'Git Bug: Interface TUI' })

vim.keymap.set('n', '<leader>gp', function()
  local cwd = get_working_dir()
  local git_root = get_git_root(cwd)

  if not git_root then
    vim.notify('Fora de um repositório Git.', vim.log.levels.ERROR)
    return
  end

  -- Validação amigável de perfil também para sincronização
  local locals, _ = get_local_identities(git_root)
  if #locals == 0 then
    vim.notify('👋 Identidade necessária para sincronizar. Crie uma em "<leader>gu".', vim.log.levels.INFO)
    return
  end

  -- Sincronização via terminal integrado
  nvim_term_exec('git bug bridge pull && git bug bridge push', git_root, false, true)
end, { desc = 'Git Bug: Push/Pull' })

local function create_issue_floating()
  local cwd = get_working_dir()
  local git_root = get_git_root(cwd)
  if not git_root then
    vim.notify('Fora de um repositório Git.', vim.log.levels.ERROR)
    return
  end
  if not ensure_repo_has_identity(git_root) then return end

  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.7)
  local height = math.floor(vim.o.lines * 0.6)
  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2 - 2,
    style = 'minimal',
    border = 'rounded',
    title = ' Nova Issue (Git Bug) ',
    title_pos = 'center',
  }
  local win = vim.api.nvim_open_win(buf, true, opts)

  local lines = {
    '# Título (obrigatório)',
    '',
    '# Descrição (opcional)',
    '',
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = 'acwrite'
  vim.bo[buf].filetype = 'markdown'

  local function submit()
    local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local title = nil
    local desc_lines = {}
    local in_desc = false

    for _, line in ipairs(content) do
      if line:match '^# Título' then
      elseif not title and not in_desc and line:match '^%s*$' then
      elseif not title and not in_desc then
        title = line:match '^%s*(.-)%s*$'
      elseif line:match '^# Descrição' then
        in_desc = true
      elseif in_desc and not line:match '^%s*$' then
        table.insert(desc_lines, line)
      end
    end

    if not title or title == '' then
      vim.notify('Título é obrigatório', vim.log.levels.WARN)
      return
    end

    local desc = table.concat(desc_lines, '\n')
    vim.api.nvim_win_close(win, true)

    local cmd = string.format('git bug bug new -t %s -m %s', vim.fn.shellescape(title), vim.fn.shellescape(desc))
    local full_cmd = string.format('cd %s && %s', vim.fn.shellescape(git_root), cmd)

    vim.notify('Criando issue...', vim.log.levels.INFO)
    vim.fn.jobstart(full_cmd, {
      on_exit = function(_, code)
        if code == 0 then
          vim.schedule(function() vim.notify('Issue criada com sucesso!', vim.log.levels.INFO) end)
        else
          vim.schedule(function() vim.notify('Erro ao criar issue. Verifique o terminal.', vim.log.levels.ERROR) end)
        end
      end,
    })
  end

  vim.keymap.set('n', '<CR>', submit, { buffer = buf })
  vim.keymap.set('n', '<C-s>', submit, { buffer = buf })
  vim.keymap.set('n', 'q', function() vim.api.nvim_win_close(win, true) end, { buffer = buf })
  vim.keymap.set('i', '<C-s>', submit, { buffer = buf })
  vim.api.nvim_win_set_cursor(win, { 2, 0 })
  vim.cmd 'startinsert'
end
vim.keymap.set('n', '<leader>ga', create_issue_floating, { desc = 'Git Bug: Nova Issue (flutuante)' })

vim.keymap.set('n', '<leader>gk', function()
  local cwd = get_working_dir()
  local git_root = get_git_root(cwd)
  if not git_root then
    vim.notify('Fora de um repositório Git.', vim.log.levels.ERROR)
    return
  end

  local output = vim.fn.system('cd ' .. vim.fn.shellescape(git_root) .. ' && git bug bug ls --format id 2>/dev/null')
  if vim.v.shell_error ~= 0 or output == '' then
    vim.notify('Nenhuma issue encontrada.', vim.log.levels.WARN)
    return
  end

  local ids = {}
  for line in output:gmatch '[^\r\n]+' do
    if line:match '^[%x]+$' then table.insert(ids, line) end
  end

  if #ids == 0 then
    vim.notify('Nenhuma issue encontrada.', vim.log.levels.WARN)
    return
  end

  vim.ui.select(ids, {
    prompt = 'Escolha o ID da issue para excluir:',
  }, function(id)
    if not id then return end

    vim.ui.select({ 'Apenas local', 'Local e remoto (push)', 'Cancelar' }, {
      prompt = 'Como deseja excluir a issue ' .. id:sub(1, 8) .. '?',
    }, function(mode)
      if not mode or mode == 'Cancelar' then return end

      local cmd_rm = string.format('git bug bug rm %s', id)
      local full_cmd = string.format('cd %s && %s', vim.fn.shellescape(git_root), cmd_rm)

      if mode == 'Apenas local' then
        local ok = os.execute(full_cmd .. ' > /dev/null 2>&1')
        if ok == 0 then
          vim.notify('Issue excluída localmente.', vim.log.levels.INFO)
        else
          vim.notify('Erro ao excluir issue.', vim.log.levels.ERROR)
        end
      else
        local push_cmd = string.format('cd %s && %s && git bug bridge push github', vim.fn.shellescape(git_root), cmd_rm)
        vim.notify('Excluindo issue e sincronizando...', vim.log.levels.INFO)
        vim.fn.jobstart(push_cmd, {
          on_exit = function(_, code)
            if code == 0 then
              vim.schedule(function() vim.notify('Issue excluída e push realizado.', vim.log.levels.INFO) end)
            else
              vim.schedule(function() vim.notify('Erro durante exclusão/push.', vim.log.levels.ERROR) end)
            end
          end,
        })
      end
    end)
  end)
end, { desc = 'Git Bug: Excluir issue' })

vim.keymap.set('n', '<leader>gp', function()
  local cwd = get_working_dir()
  local git_root = get_git_root(cwd)
  if not git_root then
    vim.notify('Fora de um repositório Git.', vim.log.levels.ERROR)
    return
  end
  gitbug_exec('git bug bridge pull github && git bug bridge push github', git_root, false, true, false)
end, { desc = 'Git Bug: Push/Pull' })

vim.keymap.set('n', '<leader>gf', function()
  local cwd = get_working_dir()
  local git_root = get_git_root(cwd)
  if not git_root then
    vim.notify('Fora de um repositório Git.', vim.log.levels.ERROR)
    return
  end
  if not ensure_repo_has_identity(git_root) then return end
  local msg = vim.fn.input 'Mensagem do Commit: '
  if msg == '' then return end
  local issue_id = vim.fn.input 'ID do Bug (ex: abc123): '
  if issue_id == '' then return end
  local cmd = string.format('git commit -m "%s (Fixes %s)"', msg, issue_id)
  gitbug_exec(cmd, git_root, false, true, false)
end, { desc = 'Git Bug: Commit Fix' })

vim.keymap.set('n', '<leader>gz', function()
  local cwd = get_working_dir()
  local git_root = get_git_root(cwd)
  if not git_root then
    vim.notify('Fora de um repositório Git.', vim.log.levels.ERROR)
    return
  end
  auto_configure_bridge(git_root)
end, { desc = 'Git Bug: Configurar bridge (gh)' })

-- Limpar keyring do git-bug (corrige bridges corrompidas)
vim.keymap.set('n', '<leader>gy', function()
  local keyring_dir = vim.fn.expand '~/.config/git-bug/keyring'

  if vim.fn.isdirectory(keyring_dir) ~= 1 then
    vim.notify('Diretório keyring não encontrado.', vim.log.levels.INFO)
    return
  end

  vim.ui.select({ 'Sim', 'Não' }, {
    prompt = 'Apagar TODAS as chaves do keyring do git-bug? Isso pode resolver bridges corrompidas.',
  }, function(choice)
    if choice == 'Sim' then
      local ok = os.execute('rm -rf ' .. vim.fn.shellescape(keyring_dir) .. '/* 2>/dev/null')
      if ok == 0 then
        vim.notify('Keyring do git-bug limpo com sucesso!', vim.log.levels.INFO)
        vim.notify('Execute <leader>gz para reconfigurar a bridge.', vim.log.levels.INFO)
      else
        vim.notify('Falha ao limpar o keyring.', vim.log.levels.ERROR)
      end
    end
  end)
end, { desc = 'Git Bug: Limpar keyring (corrigir bridge)' })
