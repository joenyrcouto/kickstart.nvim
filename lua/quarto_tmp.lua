local fn = vim.fn
local api = vim.api

local quarto_group = api.nvim_create_augroup('QuartoShadowSync', { clear = true })
local shadow_root = '/tmp/nvim_quarto_shadow'
fn.mkdir(shadow_root, 'p')

-- =========================================================================
--  Verificação de filetype suportado
-- =========================================================================
local function is_supported_extension(bufnr)
  local buf_name = api.nvim_buf_get_name(bufnr)
  if buf_name == '' then return false end
  local ext = fn.fnamemodify(buf_name, ':e')
  return ext == 'qmd' or ext == 'md' or ext == 'Rmd' or ext == 'rmd'
end

-- =========================================================================
--  Gerenciamento do YAML (frontmatter) do buffer
-- =========================================================================

local function inside_code_block(lines, idx)
  local in_block = false
  for i = 1, idx do
    if lines[i]:match '^```' then in_block = not in_block end
  end
  return in_block
end

local function get_yaml_range(bufnr)
  if not is_supported_extension(bufnr) then return nil end
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  if #lines == 0 then return nil end
  local start = nil
  for i = 1, #lines do
    if not inside_code_block(lines, i) then
      if lines[i]:match '^%s*---%s*$' then
        start = i
        break
      end
    end
  end
  if not start then return nil end
  for i = start + 1, #lines do
    if not inside_code_block(lines, i) then
      if lines[i]:match '^%s*---%s*$' then return start, i end
    end
  end
  return nil
end

local function parse_yaml_config(bufnr)
  if not is_supported_extension(bufnr) then return {} end
  local start, finish = get_yaml_range(bufnr)
  if not start then return {} end
  local lines = api.nvim_buf_get_lines(bufnr, start, finish - 1, false)
  local config = {}
  for _, line in ipairs(lines) do
    local key, value = line:match '^(quarto_[%w_]+):%s*(.*)$'
    if key then
      if value == 'true' then
        config[key] = true
      elseif value == 'false' then
        config[key] = false
      elseif value:match '^%[.*%]$' then
        local items = {}
        for item in value:gmatch '%[?([^,%[%]]+)%]?' do
          local clean = item:match '^%s*(.-)%s*$'
          if clean and clean ~= '' then table.insert(items, clean) end
        end
        config[key] = items
      else
        config[key] = value
      end
    end
  end
  return config
end

local function update_yaml_config(bufnr, updates)
  if not is_supported_extension(bufnr) then return end
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local start, finish = get_yaml_range(bufnr)
  if not start then
    local new_lines = { '---' }
    for k, v in pairs(updates) do
      if type(v) == 'boolean' then
        table.insert(new_lines, k .. ': ' .. tostring(v))
      elseif type(v) == 'table' then
        table.insert(new_lines, k .. ': [' .. table.concat(v, ', ') .. ']')
      else
        table.insert(new_lines, k .. ': ' .. tostring(v))
      end
    end
    table.insert(new_lines, '---')
    api.nvim_buf_set_lines(bufnr, 0, 0, false, new_lines)
    return
  end
  local yaml_lines = {}
  for i = start + 1, finish - 1 do
    table.insert(yaml_lines, lines[i])
  end
  local key_to_index = {}
  for idx, line in ipairs(yaml_lines) do
    local key = line:match '^([%w_]+):'
    if key then key_to_index[key] = idx end
  end
  for k, v in pairs(updates) do
    local new_line
    if type(v) == 'boolean' then
      new_line = k .. ': ' .. tostring(v)
    elseif type(v) == 'table' then
      new_line = k .. ': [' .. table.concat(v, ', ') .. ']'
    else
      new_line = k .. ': ' .. tostring(v)
    end
    if key_to_index[k] then
      yaml_lines[key_to_index[k]] = new_line
    else
      table.insert(yaml_lines, new_line)
    end
  end
  local new_block = { '---' }
  for _, line in ipairs(yaml_lines) do
    table.insert(new_block, line)
  end
  table.insert(new_block, '---')
  api.nvim_buf_set_lines(bufnr, start - 1, finish, false, new_block)
end

-- =========================================================================
--  Configuração do buffer (cache + YAML)
-- =========================================================================
local buffer_config_cache = {}

local default_config = {
  quarto_id = nil,
  quarto_push_comp = false, -- "forçar Push de arquivos para pasta do Quarto"
  quarto_modo_escrita = false,
  quarto_usar_local_fisico = true, -- true = local físico, false = usar tmp
  quarto_ignorar_ativos = true,
  quarto_modo_rapido = false, -- Modo Rápido (sem execução de código)
  quarto_outputfile = true, -- Vai usar o quarto_id para o arg de output-file
  quarto_gerais = {},
  quarto_extensoes = {},
}

local function get_buffer_config(bufnr)
  if buffer_config_cache[bufnr] then return buffer_config_cache[bufnr] end
  if not is_supported_extension(bufnr) then
    local config = vim.deepcopy(default_config)
    buffer_config_cache[bufnr] = config
    return config
  end
  local yaml = parse_yaml_config(bufnr)
  local config = vim.tbl_deep_extend('force', {}, default_config, yaml)
  if not config.quarto_id then
    config.quarto_usar_local_fisico = true
    config.quarto_ignorar_ativos = true
  end
  local gerais_set = {}
  for _, name in ipairs(config.quarto_gerais or {}) do
    gerais_set[name] = true
  end
  local extensoes_set = {}
  for _, name in ipairs(config.quarto_extensoes or {}) do
    extensoes_set[name] = true
  end
  config.quarto_gerais = gerais_set
  config.quarto_extensoes = extensoes_set
  buffer_config_cache[bufnr] = config
  return config
end

local function save_buffer_config(bufnr)
  if not is_supported_extension(bufnr) then return end
  local config = buffer_config_cache[bufnr]
  if not config then return end
  local updates = {
    quarto_id = config.quarto_id,
    quarto_push_comp = config.quarto_push_comp,
    quarto_modo_escrita = config.quarto_modo_escrita,
    quarto_usar_local_fisico = config.quarto_usar_local_fisico,
    quarto_ignorar_ativos = config.quarto_ignorar_ativos,
    quarto_modo_rapido = config.quarto_modo_rapido,
    quarto_outputfile = config.quarto_outputfile,
    quarto_gerais = vim.tbl_keys(config.quarto_gerais),
    quarto_extensoes = vim.tbl_keys(config.quarto_extensoes),
  }
  update_yaml_config(bufnr, updates)
end

local function ensure_buffer_id(bufnr, force_create)
  if not is_supported_extension(bufnr) then return fn.sha256(tostring(os.time()) .. tostring(bufnr)):sub(1, 8) end
  local config = get_buffer_config(bufnr)
  if not config.quarto_id and force_create then
    local buf_name = api.nvim_buf_get_name(bufnr)
    local base = buf_name ~= '' and buf_name or tostring(os.time())
    config.quarto_id = fn.sha256(base .. os.time()):sub(1, 8)
    save_buffer_config(bufnr)
  end
  return config.quarto_id
end

-- =========================================================================
--  Função para perguntar se deseja criar configuração shadow
-- =========================================================================
local function prompt_shadow_setup(bufnr, reason)
  local choice = vim.fn.confirm(
    'Arquivo sem configuração Quarto (sem ID). Deseja criar configuração shadow (RAM) para "'
      .. reason
      .. '"?\n'
      .. 'Sim: cria ID e permite preview/compilação otimizada.\n'
      .. 'Não: usará modo local (sem /tmp).',
    '&Sim\n&Não',
    1,
    'Question'
  )
  if choice == 1 then
    ensure_buffer_id(bufnr, true)
    buffer_config_cache[bufnr] = nil
    local config = get_buffer_config(bufnr)
    config.quarto_usar_local_fisico = false
    config.quarto_ignorar_ativos = false
    save_buffer_config(bufnr)
    return true
  else
    local config = get_buffer_config(bufnr)
    config.quarto_usar_local_fisico = true
    return false
  end
end

-- =========================================================================
--  UI Helpers
-- =========================================================================
local function open_menu(title, lines, width_offset)
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local width = width_offset or 75
  local height = math.max(8, math.min(#lines + 2, math.floor(vim.o.lines * 0.8)))
  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    style = 'minimal',
    border = 'rounded',
    title = ' ' .. title .. ' ',
    title_pos = 'center',
  }
  local win = api.nvim_open_win(buf, true, opts)
  vim.wo[win].winhl = 'Normal:Normal,FloatBorder:FloatBorder'
  vim.keymap.set('n', 'q', '<cmd>q<CR>', { buffer = buf, silent = true, nowait = true })
  vim.keymap.set('n', '<Esc>', '<cmd>q<CR>', { buffer = buf, silent = true, nowait = true })
  return buf, win
end

local function open_log_view(path)
  if fn.filereadable(path) == 1 then
    vim.cmd('vsplit ' .. fn.fnameescape(path))
    local log_buf = api.nvim_get_current_buf()
    local log_win = api.nvim_get_current_win()
    vim.cmd 'normal! G'
    vim.bo[log_buf].buflisted = false
    vim.bo[log_buf].buftype = 'nofile'
    vim.bo[log_buf].bufhidden = 'wipe'
    local close_log = function()
      if api.nvim_win_is_valid(log_win) then api.nvim_win_close(log_win, true) end
    end
    vim.keymap.set('n', 'q', close_log, { buffer = log_buf, silent = true })
    vim.keymap.set('n', '<C-x>', close_log, { buffer = log_buf, silent = true })
  else
    vim.notify('Log não encontrado: ' .. path, vim.log.levels.WARN)
  end
end

-- =========================================================================
--  Shadow Sync
-- =========================================================================
local function get_shadow_info(bufnr)
  local buf_name = api.nvim_buf_get_name(bufnr)
  if buf_name == '' then return nil end
  local name = fn.fnamemodify(buf_name, ':t')
  local id = ensure_buffer_id(bufnr, false)
  if not id then return nil end
  local work_dir = shadow_root .. '/' .. id
  fn.mkdir(work_dir, 'p')
  return { dir = work_dir, path = work_dir .. '/' .. name }
end

local function update_shadow_from_buffer(bufnr)
  if not is_supported_extension(bufnr) then return nil end
  local info = get_shadow_info(bufnr)
  if not info then return nil end
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  fn.writefile(lines, info.path)
  return info
end

-- =========================================================================
--  Sincronização de Ativos (Gerais e Extensões)
-- =========================================================================
local function sync_assets(target_dir, config)
  if config.quarto_ignorar_ativos then return end
  if config.quarto_gerais and next(config.quarto_gerais) then
    local gdir = fn.expand '~/Documents/Quarto/Gerais'
    for name, active in pairs(config.quarto_gerais) do
      if active then
        local src = gdir .. '/' .. name
        if fn.isdirectory(src) == 1 or fn.filereadable(src) == 1 then fn.system { 'cp', '-r', src, target_dir .. '/' } end
      end
    end
  end
  if config.quarto_extensoes and next(config.quarto_extensoes) then
    local edir = fn.expand '~/Documents/Quarto/Extens'
    local ext_dest = target_dir .. '/_extensions'
    fn.mkdir(ext_dest, 'p')
    for name, active in pairs(config.quarto_extensoes) do
      if active then
        local src = edir .. '/' .. name
        if fn.isdirectory(src) == 1 then fn.system { 'cp', '-r', src, ext_dest .. '/' } end
      end
    end
  end
end

-- =========================================================================
--  Extração de Blocos (versão melhorada para detectar chaves)
-- =========================================================================
local function get_all_blocks(bufnr)
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local blocks = {}
  local in_block, block_start, block_lang, has_braces = false, 0, '', false
  for i, line in ipairs(lines) do
    if not in_block then
      local lang_braces = line:match '^```{%s*([^%s,}]+)'
      local lang_simple = line:match '^```(%a+)$'
      if lang_braces then
        in_block, block_start, block_lang, has_braces = true, i, lang_braces, true
      elseif lang_simple then
        in_block, block_start, block_lang, has_braces = true, i, lang_simple, false
      end
    else
      if line:match '^```$' then
        table.insert(blocks, {
          start = block_start,
          finish = i,
          lang = block_lang,
          has_braces = has_braces,
        })
        in_block = false
      end
    end
  end
  return blocks
end

-- =========================================================================
--  Manipulação de Blocos: alternar entre ```{lang} e ```lang
-- =========================================================================
local function toggle_block_braces(bufnr, block_idx)
  local blocks = get_all_blocks(bufnr)
  if block_idx < 1 or block_idx > #blocks then
    vim.notify('Bloco inválido.', vim.log.levels.ERROR)
    return
  end
  local blk = blocks[block_idx]
  local new_line
  if blk.has_braces then
    new_line = '```' .. blk.lang
  else
    new_line = '```{' .. blk.lang .. '}'
  end
  api.nvim_buf_set_lines(bufnr, blk.start - 1, blk.start, false, { new_line })
  vim.notify(string.format('Bloco %d alternado para %s', block_idx, blk.has_braces and 'sem chaves' or 'com chaves'), vim.log.levels.INFO)
end

local function remove_block(bufnr, block_idx)
  local blocks = get_all_blocks(bufnr)
  if block_idx < 1 or block_idx > #blocks then
    vim.notify('Bloco inválido.', vim.log.levels.ERROR)
    return
  end
  local blk = blocks[block_idx]
  api.nvim_buf_set_lines(bufnr, blk.start - 1, blk.finish, false, {})
  vim.notify(string.format('Bloco %d removido.', block_idx), vim.log.levels.INFO)
end

local function copy_block_content(bufnr, block_idx)
  local blocks = get_all_blocks(bufnr)
  if block_idx < 1 or block_idx > #blocks then
    vim.notify('Bloco inválido.', vim.log.levels.ERROR)
    return
  end
  local blk = blocks[block_idx]
  local lines = api.nvim_buf_get_lines(bufnr, blk.start, blk.finish - 1, false)
  local content = table.concat(lines, '\n')
  fn.setreg('+', content)
  vim.notify(string.format('Conteúdo do bloco %d copiado.', block_idx), vim.log.levels.INFO)
  return content
end

local function send_block_to_repl(bufnr, block_idx)
  local content = copy_block_content(bufnr, block_idx)
  if not content then return end
  local slime_ok, slime = pcall(require, 'slime')
  if slime_ok then
    slime.send(content)
    vim.notify('Bloco enviado para REPL.', vim.log.levels.INFO)
  else
    vim.notify('vim-slime não encontrado.', vim.log.levels.WARN)
  end
end

-- =========================================================================
--  Preview State
-- =========================================================================
local preview_state = {
  job = nil,
  port = 4445,
  url = nil,
  mode = nil,
  bufnr = nil,
  config = nil,
  browser_opened = false,
  browser_pid = nil,
  browser_temp_profile = nil,
  browser_window_title = nil,
}

local geometry_file = vim.fn.stdpath('state') .. '/quarto_preview_geometry.txt'

local function save_window_geometry()
  local title_hint = preview_state.browser_window_title
  if not title_hint then return end
  local wid = vim.fn.system("xdotool search --onlyvisible --name '" .. title_hint .. "' 2>/dev/null | head -1"):gsub('%s+', '')
  if wid ~= '' then
    local geom = vim.fn.system("xdotool getwindowgeometry --shell " .. wid .. " 2>/dev/null")
    local x = geom:match("X=(%-?%d+)")
    local y = geom:match("Y=(%-?%d+)")
    local w = geom:match("WIDTH=(%d+)")
    local h = geom:match("HEIGHT=(%d+)")
    if x and y and w and h then
      vim.fn.writefile({ table.concat({ x, y, w, h }, ',') }, geometry_file)
    end
  end
end

local function load_window_geometry()
  if vim.fn.filereadable(geometry_file) == 1 then
    local content = vim.fn.readfile(geometry_file)
    if #content > 0 then
      local parts = {}
      for n in content[1]:gmatch('[^,]+') do table.insert(parts, n) end
      if #parts == 4 then
        return {
          x = tonumber(parts[1]),
          y = tonumber(parts[2]),
          width = tonumber(parts[3]),
          height = tonumber(parts[4]),
        }
      end
    end
  end
  return nil
end

local function apply_window_geometry()
  local geom = load_window_geometry()
  local title_hint = preview_state.browser_window_title
  if geom and title_hint then
    vim.defer_fn(function()
      local wid = vim.fn.system("xdotool search --onlyvisible --name '" .. title_hint .. "' 2>/dev/null | head -1"):gsub('%s+', '')
      if wid ~= '' then
        os.execute("xdotool windowmove --sync " .. wid .. " " .. geom.x .. " " .. geom.y .. " 2>/dev/null")
        os.execute("xdotool windowsize --sync " .. wid .. " " .. geom.width .. " " .. geom.height .. " 2>/dev/null")
      end
    end, 1000)
  end
end

local function open_browser_with_temp_profile(url, title_hint)
  local script = os.tmpname() .. '.sh'
  local f = io.open(script, 'w')
  if not f then return end
  f:write([[
#!/bin/bash
BROWSER_DESKTOP=$(xdg-settings get default-web-browser)
BROWSER_EXEC=$(grep -Po '(?<=^Exec=).*?(?=(\s|$))' "/usr/share/applications/$BROWSER_DESKTOP" 2>/dev/null | head -1 | sed 's/%.//')
TEMP_PROFILE=$(mktemp -d)
$BROWSER_EXEC --user-data-dir="$TEMP_PROFILE" --no-first-run --no-default-browser-check --ozone-platform=x11 "]] .. url .. [[" &
PID=$!
echo "PID=$PID"
echo "TEMP_PROFILE=$TEMP_PROFILE"
]])
  f:close()
  local output = vim.fn.system({ 'bash', script })
  os.remove(script)
  local pid, profile
  for line in output:gmatch '[^\r\n]+' do
    local p = line:match '^PID=(%d+)$'
    if p then pid = tonumber(p) end
    local pf = line:match '^TEMP_PROFILE=(.+)$'
    if pf then profile = pf end
  end
  if pid and profile then
    preview_state.browser_pid = pid
    preview_state.browser_temp_profile = profile
    preview_state.browser_window_title = title_hint
    vim.notify('Navegador iniciado. PID=' .. pid, vim.log.levels.INFO)
  else
    vim.notify('Falha ao capturar PID ou perfil', vim.log.levels.ERROR)
  end
end

-- Copia conteúdo do diretório de origem para destino, sobrescrevendo sem apagar
local function copy_dir_contents(src, dest)
  fn.mkdir(dest, 'p')
  fn.system({ 'cp', '-r', src .. '/.', dest .. '/' })
end

local function stop_preview()
  -- Salva a geometria da janela antes de fechar
  save_window_geometry()
  -- Mata o navegador do preview anterior
  if preview_state.browser_pid then
    fn.system("kill " .. preview_state.browser_pid .. " 2>/dev/null")
    fn.system("kill -9 " .. preview_state.browser_pid .. " 2>/dev/null")
    preview_state.browser_pid = nil
  end
  -- Remove o perfil temporário
  if preview_state.browser_temp_profile then
    fn.system("rm -rf " .. preview_state.browser_temp_profile .. " 2>/dev/null")
    preview_state.browser_temp_profile = nil
  end
  -- Mata o job interno (bash)
  if preview_state.job then
    pcall(vim.fn.jobstop, preview_state.job)
    preview_state.job = nil
  end
  -- Libera a porta 4445
  fn.system("fuser -k 4445/tcp >/dev/null 2>&1")
  -- Limpa estado
  preview_state.mode = nil
  preview_state.browser_opened = false
end

local function start_preview(shadow_info, file_path, fmt, config)
  stop_preview()

  vim.wait(500, function() return false end)  -- Aguarda 500ms para a porta liberar

  local cmd_parts = {
    'quarto',
    'preview',
    fn.shellescape(file_path),
    '--to',
    fn.shellescape(fmt),
    '--port',
    tostring(preview_state.port),
    '--no-browser',
  }

  if config.quarto_modo_rapido then table.insert(cmd_parts, '--no-execute') end

  if config.quarto_outputfile then
    -- Força o nome de saída como 'index' para que a raiz seja servida
    local outname = 'index.' .. fmt  -- index.html ou index.pdf
    table.insert(cmd_parts, '--output')
    table.insert(cmd_parts, fn.shellescape(outname))
  end

  local cmd = table.concat(cmd_parts, ' ')
  preview_state.mode = 'compile'
  preview_state.bufnr = api.nvim_get_current_buf()
  preview_state.config = config

  local log_path = shadow_info.dir .. '/preview.log'
  fn.writefile({ '=== Preview Log === ' .. os.date(), '' }, log_path)

  vim.notify('Iniciando preview (' .. fmt:upper() .. ')...', vim.log.levels.INFO)

  local function process_output_for_url(data)
    if not data then return end
    for _, line in ipairs(data) do
      local clean_line = line:gsub('\x1b%[[0-9;]*[a-zA-Z]', '')
      local url = clean_line:match '(http://localhost:%d+/[^%s]+)'
      if url and not preview_state.browser_opened then
      preview_state.url = url
      preview_state.browser_opened = true
      vim.schedule(function()
        local title_hint = fn.fnamemodify(file_path, ':t:r')
        open_browser_with_temp_profile(url, title_hint)
        apply_window_geometry()
        -- Se push_comp ativo e não local, copia para subpasta nome_id
        if config.quarto_push_comp and not config.quarto_usar_local_fisico then
          local fname_no_ext = fn.fnamemodify(file_path, ':t:r')
          local base_comp = fn.expand '~/Documents/Quarto/Comp/'
          local comp_subdir = base_comp .. fname_no_ext .. '_' .. config.quarto_id .. '/'
          copy_dir_contents(shadow_info.dir, comp_subdir)
          vim.notify('Preview copiado para ' .. comp_subdir, vim.log.levels.INFO)
        end
        vim.notify('Preview disponível em ' .. url, vim.log.levels.INFO)
      end)
    end
    end
  end

  preview_state.job = fn.jobstart({ 'bash', '-c', cmd }, {
    cwd = shadow_info.dir,
    stdout_buffered = false,
    stderr_buffered = false,

    on_stdout = function(_, data)
      if data then
        local f = io.open(log_path, 'a')
        if f then
          for _, line in ipairs(data) do
            f:write(line .. '\n')
          end
          f:close()
        end
        process_output_for_url(data)
      end
    end,

    on_stderr = function(_, data)
      if data then
        local f = io.open(log_path, 'a')
        if f then
          for _, line in ipairs(data) do
            f:write('[stderr] ' .. line .. '\n')
          end
          f:close()
        end
        process_output_for_url(data)
      end
    end,

    on_exit = function(_, code)
      if code ~= 0 and code ~= 143 then
        vim.schedule(function()
          vim.notify('Preview falhou. Abrindo log...', vim.log.levels.ERROR)
          open_log_view(log_path)
        end)
      end
      preview_state.job = nil
    end,
  })
end

-- Debounce para evitar spam de "Preview atualizado"
local refresh_timer = nil
local function refresh_preview()
  if not preview_state.job then
    vim.notify('Nenhum preview ativo.', vim.log.levels.WARN)
    return
  end
  local bufnr = preview_state.bufnr
  if not api.nvim_buf_is_valid(bufnr) then
    vim.notify('Buffer original não disponível.', vim.log.levels.ERROR)
    return
  end
  local config = get_buffer_config(bufnr)
  if not config.quarto_modo_escrita then return end
  if refresh_timer then
    refresh_timer:stop()
    refresh_timer:close()
  end
  refresh_timer = vim.defer_fn(function()
    local info = update_shadow_from_buffer(bufnr)
    if info then fn.system('touch ' .. fn.shellescape(info.path)) end
    refresh_timer = nil
  end, 500)
end

-- =========================================================================
--  Comando :Quarto
-- =========================================================================
local function quarto_handler(args)
  local bufnr = api.nvim_get_current_buf()
  local original_path = api.nvim_buf_get_name(bufnr)
  if original_path == '' then
    vim.notify('Salve o arquivo primeiro.', vim.log.levels.ERROR)
    return
  end

  if not is_supported_extension(bufnr) then
    vim.notify('Arquivo não suportado. Use .qmd ou .md', vim.log.levels.WARN)
    return
  end

  local config = get_buffer_config(bufnr)
  local fargs = args.fargs
  local flag = fargs[1]

  if #fargs == 0 or flag == '-h' then
    open_menu('Quarto - Ajuda', {
      ' :Quarto -p [fmt]      → Preview (pdf ou html)',
      ' :Quarto -r            → Atualizar preview',
      ' :Quarto -k            → Parar preview',
      ' :Quarto -c [fmt]      → Renderizar final',
      ' :Quarto -b            → Gerenciar blocos',
      ' :Quarto -l            → Logs',
      ' :Quarto -m            → Configurações',
      '',
      ' q para fechar',
    }, 75)
    return
  end

  local needs_shadow = (flag == '-p' or flag == '-c' or flag == '-m')
  local has_id = config.quarto_id ~= nil

  if needs_shadow and not has_id then
    local reason = (flag == '-p' and 'preview') or (flag == '-c' and 'renderização') or 'configuração'
    local accepted = prompt_shadow_setup(bufnr, reason)
    config = get_buffer_config(bufnr)
    has_id = config.quarto_id ~= nil
    if not accepted then
      if flag == '-m' then
        local lines = {
          ' === Configurações (Modo Local) ===',
          '',
          ' 1. Modo Escrita: ' .. tostring(config.quarto_modo_escrita),
          ' 2. Modo Rápido (sem executar código): ' .. tostring(config.quarto_modo_rapido),
          ' 3. Templates',
          '',
          ' (Sem shadow ativo)',
          '',
          ' Pressione 1/2/3 para alternar/abrir, q para sair',
        }
        local buf_main, win_main = open_menu('Configurações (Local)', lines, 60)
        local function update_line()
          lines[3] = ' 1. Modo Escrita: ' .. tostring(config.quarto_modo_escrita)
          lines[4] = ' 2. Modo Rápido (sem executar código): ' .. tostring(config.quarto_modo_rapido)
          api.nvim_buf_set_lines(buf_main, 0, -1, false, lines)
        end
        local function open_templates_local()
          local tdir = fn.expand '~/Documents/Quarto/Temp'
          fn.mkdir(tdir, 'p')
          local items = fn.readdir(tdir)
          local t_lines = { ' === Templates (número para selecionar) ===', '' }
          for i, name in ipairs(items) do
            table.insert(t_lines, string.format(' %d. %s', i, name))
          end
          table.insert(t_lines, '')
          table.insert(t_lines, ' Pressione o número ou Enter sobre o item')
          local tbuf, twin = open_menu('Templates', t_lines, 60)
          local function close_all_menus()
            for _, w in ipairs(api.nvim_list_wins()) do
              local cfg = api.nvim_win_get_config(w)
              if cfg.relative == 'editor' and cfg.border then
                api.nvim_win_close(w, true)
              end
            end
          end
          local function show_action_menu(name)
            local action_lines = { ' === Ação: ' .. name .. ' ===', '', ' 1. Usar template (substituir buffer)', ' 2. Copiar para clipboard', ' 3. Abrir em split', '', ' q ou Esc para cancelar' }
            local abuf, awin = open_menu('Ação', action_lines, 55)
            vim.keymap.set('n', '1', function()
              local content = fn.readfile(tdir .. '/' .. name)
              api.nvim_buf_set_lines(bufnr, 0, -1, false, content)
              buffer_config_cache[bufnr] = nil
              local new_config = get_buffer_config(bufnr)
              new_config.quarto_id = fn.sha256(api.nvim_buf_get_name(bufnr) .. os.time()):sub(1, 8)
              save_buffer_config(bufnr)
              close_all_menus()
            end, { buffer = abuf })
            vim.keymap.set('n', '2', function()
              fn.setreg('+', table.concat(fn.readfile(tdir .. '/' .. name), '\n'))
              api.nvim_win_close(awin, true)
            end, { buffer = abuf })
            vim.keymap.set('n', '3', function()
              close_all_menus()
              vim.cmd('split ' .. fn.fnameescape(tdir .. '/' .. name))
            end, { buffer = abuf })
            return awin
          end
          -- Keymaps numéricos para templates locais
          for i = 1, #items do
            vim.keymap.set('n', tostring(i), function()
              local name = items[i]
              show_action_menu(name)
            end, { buffer = tbuf })
          end
          -- Enter sobre o item
          vim.keymap.set('n', '<CR>', function()
            if not api.nvim_win_is_valid(twin) then return end
            local cursor_idx = api.nvim_win_get_cursor(twin)[1]
            local item_idx = cursor_idx - 2
            if item_idx > 0 and item_idx <= #items then
              local name = items[item_idx]
              show_action_menu(name)
            end
          end, { buffer = tbuf })
        end
        vim.keymap.set('n', '1', function()
          config.quarto_modo_escrita = not config.quarto_modo_escrita
          update_line()
        end, { buffer = buf_main })
        vim.keymap.set('n', '2', function()
          config.quarto_modo_rapido = not config.quarto_modo_rapido
          update_line()
        end, { buffer = buf_main })
        vim.keymap.set('n', '3', open_templates_local, { buffer = buf_main })
        vim.keymap.set('n', '<CR>', function()
          local cursor = api.nvim_win_get_cursor(win_main)[1]
          if cursor == 3 then
            config.quarto_modo_escrita = not config.quarto_modo_escrita
            update_line()
          elseif cursor == 4 then
            config.quarto_modo_rapido = not config.quarto_modo_rapido
            update_line()
          elseif cursor == 5 then
            open_templates_local()
          end
        end, { buffer = buf_main })
        return
      end
    end
  end

  local shadow_info = nil
  if flag == '-r' or flag == '-k' or flag == '-l' or flag == '-p' or flag == '-c' then
    if config.quarto_usar_local_fisico then
      shadow_info = { dir = fn.fnamemodify(original_path, ':p:h'), path = original_path }
    else
      shadow_info = update_shadow_from_buffer(bufnr)
      if not shadow_info then
        vim.notify('Erro ao preparar shadow. Usando local.', vim.log.levels.WARN)
        shadow_info = { dir = fn.fnamemodify(original_path, ':p:h'), path = original_path }
      end
    end
  end

  local filename_with_ext = fn.fnamemodify(original_path, ':t')
  local filename_no_ext = fn.fnamemodify(original_path, ':t:r')

  if flag == '-r' then
    refresh_preview()
    return
  end
  if flag == '-k' then
    stop_preview()
    vim.notify('Preview parado.', vim.log.levels.INFO)
    return
  end
  if flag == '-l' then
    local preview_log = shadow_info.dir .. '/preview.log'
    local render_log = shadow_info.dir .. '/render.log'
    vim.ui.select({ 'Preview', 'Render' }, { prompt = 'Ver log de:' }, function(choice)
      if choice == 'Preview' then
        open_log_view(preview_log)
      elseif choice == 'Render' then
        open_log_view(render_log)
      end
    end)
    return
  end

  if flag == '-p' then
    local fmt = 'html'
    if fargs[2] and (fargs[2] == 'pdf' or fargs[2] == 'html') then fmt = fargs[2] end
    sync_assets(shadow_info.dir, config)
    start_preview(shadow_info, filename_with_ext, fmt, config)
    return
  end

  if flag == '-c' then
    local fmt = 'pdf'
    if fargs[2] and (fargs[2] == 'pdf' or fargs[2] == 'html') then fmt = fargs[2] end
    vim.notify('Renderizando ' .. fmt .. '...', vim.log.levels.INFO)

    local compile_dir = shadow_info.dir
    if config.quarto_usar_local_fisico then vim.cmd 'silent! write' end
    sync_assets(compile_dir, config)

    local render_log = compile_dir .. '/render.log'
    local log_lines = { '=== Render Log === ' .. os.date(), '' }
    local function capture(_, data)
      if data then
        for _, l in ipairs(data) do
          if l ~= '' then table.insert(log_lines, l) end
        end
      end
    end

    local cmd_args = { 'quarto', 'render', filename_with_ext, '--to', fmt }
    if config.quarto_modo_rapido then table.insert(cmd_args, '--no-execute') end
    fn.jobstart(cmd_args, {
      cwd = compile_dir,
      on_stdout = capture,
      on_stderr = capture,
      on_exit = function(_, code)
        fn.writefile(log_lines, render_log)
        if code == 0 then
          vim.notify('Render concluído.', vim.log.levels.INFO)
          local out_ext = (fmt == 'latex' and 'tex') or fmt
          if not config.quarto_usar_local_fisico then
            -- Modo tmp: copiar resultado para subpasta nome_id
            local base_comp = fn.expand '~/Documents/Quarto/Comp/'
            local comp_subdir = base_comp .. filename_no_ext .. '_' .. config.quarto_id .. '/'
            copy_dir_contents(compile_dir, comp_subdir)
            vim.notify('Arquivos copiados para ' .. comp_subdir, vim.log.levels.INFO)
            -- Abrir o arquivo a partir da cópia
            local copied_file = comp_subdir .. filename_no_ext .. '.' .. out_ext
            if fn.filereadable(copied_file) == 1 then
              local title_hint = filename_no_ext
              open_browser_with_temp_profile(copied_file, title_hint)
            end
          else
            -- Modo local: abrir diretamente do diretório original
            local expected_file = compile_dir .. '/' .. filename_no_ext .. '.' .. out_ext
            if fn.filereadable(expected_file) == 1 then
              local title_hint = filename_no_ext
              open_browser_with_temp_profile(expected_file, title_hint)
            end
          end
        else
        vim.schedule(function()
            vim.notify('Erro na renderização. Abrindo log...', vim.log.levels.ERROR)
            open_log_view(render_log)
        end)
      end
    end,
    })
    return
  end

  if flag == '-b' then
    local blocks = get_all_blocks(bufnr)
    if #blocks == 0 then
      vim.notify('Nenhum bloco de código encontrado.', vim.log.levels.WARN)
      return
    end

    local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local menu_lines = { ' === Blocos de Código ===', '' }

    local function build_menu_lines(blocks_list)
      local all_braces = true
      for _, blk in ipairs(blocks_list) do
        if not blk.has_braces then all_braces = false end
      end
      local new_menu = { ' === Blocos de Código ===', '' }
      table.insert(new_menu, string.format(' 0. %s', all_braces and '[X] Marcar todos como NÃO executar' or '[ ] Marcar todos como executar'))
      local buf_lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
      for i, blk in ipairs(blocks_list) do
        local preview = table.concat(vim.list_slice(buf_lines, blk.start, blk.finish), ' '):gsub('\n', ' '):sub(1, 40)
        table.insert(new_menu, string.format(' %d. [%s] %s : %s...', i, blk.has_braces and '✓' or ' ', blk.lang, preview))
      end
      table.insert(new_menu, '')
      table.insert(new_menu, ' Atalhos: <Enter> ou número = alternar execução')
      table.insert(new_menu, '          r = enviar p/ REPL | p = copiar | R = remover | d = copiar e remover')
      return new_menu
    end

    menu_lines = build_menu_lines(blocks)
    local buf, win = open_menu('Blocos', menu_lines, 80)

    local function refresh_menu()
      local new_blocks = get_all_blocks(bufnr)
      local new_menu = build_menu_lines(new_blocks)
      api.nvim_buf_set_lines(buf, 0, -1, false, new_menu)
      return new_blocks
    end

    local function toggle_all()
      local cur_blocks = get_all_blocks(bufnr)
      local all_have_braces = true
      for _, blk in ipairs(cur_blocks) do
        if not blk.has_braces then all_have_braces = false end
      end
      local target_has_braces = not all_have_braces
      for i, blk in ipairs(cur_blocks) do
        if blk.has_braces ~= target_has_braces then toggle_block_braces(bufnr, i) end
      end
      refresh_menu()
    end

    vim.keymap.set('n', '0', toggle_all, { buffer = buf })
    for i = 1, #blocks do
      vim.keymap.set('n', tostring(i), function()
        toggle_block_braces(bufnr, i)
        refresh_menu()
      end, { buffer = buf })
    end

    vim.keymap.set('n', '<CR>', function()
      local cursor = api.nvim_win_get_cursor(win)[1]
      if cursor == 3 then
        toggle_all()
      elseif cursor >= 4 and cursor <= 3 + #blocks then
        local idx = cursor - 3
        toggle_block_braces(bufnr, idx)
        refresh_menu()
      end
    end, { buffer = buf })

    vim.keymap.set('n', 'r', function()
      local cursor = api.nvim_win_get_cursor(win)[1]
      if cursor >= 4 and cursor <= 3 + #blocks then
        local idx = cursor - 3
        send_block_to_repl(bufnr, idx)
      else
        vim.notify('Posicione o cursor sobre um bloco.', vim.log.levels.WARN)
      end
    end, { buffer = buf })

    vim.keymap.set('n', 'p', function()
      local cursor = api.nvim_win_get_cursor(win)[1]
      if cursor >= 4 and cursor <= 3 + #blocks then
        local idx = cursor - 3
        copy_block_content(bufnr, idx)
      else
        vim.notify('Posicione o cursor sobre um bloco.', vim.log.levels.WARN)
      end
    end, { buffer = buf })

    vim.keymap.set('n', 'R', function()
      local cursor = api.nvim_win_get_cursor(win)[1]
      if cursor >= 4 and cursor <= 3 + #blocks then
        local idx = cursor - 3
        remove_block(bufnr, idx)
        refresh_menu()
        vim.notify('Bloco removido.', vim.log.levels.INFO)
      else
        vim.notify('Posicione o cursor sobre um bloco.', vim.log.levels.WARN)
      end
    end, { buffer = buf })

    vim.keymap.set('n', 'd', function()
      local cursor = api.nvim_win_get_cursor(win)[1]
      if cursor >= 4 and cursor <= 3 + #blocks then
        local idx = cursor - 3
        copy_block_content(bufnr, idx)
        remove_block(bufnr, idx)
        refresh_menu()
        vim.notify('Bloco copiado e removido.', vim.log.levels.INFO)
      else
        vim.notify('Posicione o cursor sobre um bloco.', vim.log.levels.WARN)
      end
    end, { buffer = buf })

    return
  end

    if flag == '-m' then
    if not config.quarto_id then
      vim.notify('Shadow não configurado. Use :Quarto -p ou -c para criar.', vim.log.levels.WARN)
      return
    end

    -- Submenus como funções nomeadas (para <Enter> funcionar)
    local function open_gerais()
      local gdir = fn.expand '~/Documents/Quarto/Gerais'
      fn.mkdir(gdir, 'p')
      local items = fn.readdir(gdir)
      -- Sempre usa o cache mais recente para montar as linhas
      local cfg = get_buffer_config(bufnr)
      local g_lines = { ' === Gerais (número para toggle) ===', '' }
      for i, name in ipairs(items) do
        table.insert(g_lines, ' ' .. i .. '. ' .. (cfg.quarto_gerais[name] and '[X]' or '[ ]') .. ' ' .. name)
      end
      table.insert(g_lines, '')
      table.insert(g_lines, ' Pressione o número ou Enter sobre o item')
      local gbuf, gwin = open_menu('Gerais', g_lines, 60)

      -- Função que realmente alterna e salva
      local function toggle_geral(item_idx)
        local name = items[item_idx]
        local cur_cfg = get_buffer_config(bufnr)
        if cur_cfg.quarto_gerais[name] then
          cur_cfg.quarto_gerais[name] = nil   -- remove do set
        else
          cur_cfg.quarto_gerais[name] = true  -- adiciona ao set
        end
        g_lines[item_idx + 2] = ' ' .. item_idx .. '. ' .. (cur_cfg.quarto_gerais[name] and '[X]' or '[ ]') .. ' ' .. name
        api.nvim_buf_set_lines(gbuf, 0, -1, false, g_lines)
        buffer_config_cache[bufnr] = cur_cfg
        save_buffer_config(bufnr)
      end

      -- Keymaps numéricos (1 a 9)
      for i = 1, math.min(#items, 9) do
        vim.keymap.set('n', tostring(i), function() toggle_geral(i) end,
          { buffer = gbuf, nowait = true, silent = true })
      end
      -- Enter sobre o item
      vim.keymap.set('n', '<CR>', function()
        local cursor_idx = api.nvim_win_get_cursor(gwin)[1]
        local item_idx = cursor_idx - 2
        if item_idx > 0 and item_idx <= #items then
          toggle_geral(item_idx)
        end
      end, { buffer = gbuf })
    end

    local function open_extensoes()
      local edir = fn.expand '~/Documents/Quarto/Extens'
      fn.mkdir(edir, 'p')
      local items = fn.readdir(edir)
      local cfg = get_buffer_config(bufnr)
      local e_lines = { ' === Extensões (número para toggle) ===', '' }
      for i, name in ipairs(items) do
        table.insert(e_lines, ' ' .. i .. '. ' .. (cfg.quarto_extensoes[name] and '[X]' or '[ ]') .. ' ' .. name)
      end
      table.insert(e_lines, '')
      table.insert(e_lines, ' Pressione o número ou Enter sobre o item')
      local ebuf, ewin = open_menu('Extensões', e_lines, 60)

      local function toggle_extensao(item_idx)
        local name = items[item_idx]
        local cur_cfg = get_buffer_config(bufnr)
        if cur_cfg.quarto_extensoes[name] then
          cur_cfg.quarto_extensoes[name] = nil
        else
          cur_cfg.quarto_extensoes[name] = true
        end
        e_lines[item_idx + 2] = ' ' .. item_idx .. '. ' .. (cur_cfg.quarto_extensoes[name] and '[X]' or '[ ]') .. ' ' .. name
        api.nvim_buf_set_lines(ebuf, 0, -1, false, e_lines)
        buffer_config_cache[bufnr] = cur_cfg
        save_buffer_config(bufnr)
      end

      for i = 1, math.min(#items, 9) do
        vim.keymap.set('n', tostring(i), function() toggle_extensao(i) end,
          { buffer = ebuf, nowait = true, silent = true })
      end
      vim.keymap.set('n', '<CR>', function()
        local cursor_idx = api.nvim_win_get_cursor(ewin)[1]
        local item_idx = cursor_idx - 2
        if item_idx > 0 and item_idx <= #items then
          toggle_extensao(item_idx)
        end
      end, { buffer = ebuf })
    end

      local function open_templates()
      local tdir = fn.expand '~/Documents/Quarto/Temp'
      fn.mkdir(tdir, 'p')
      local items = fn.readdir(tdir)
      local t_lines = { ' === Templates (número para selecionar) ===', '' }
      for i, name in ipairs(items) do
        table.insert(t_lines, string.format(' %d. %s', i, name))
      end
      table.insert(t_lines, '')
      table.insert(t_lines, ' Pressione o número ou Enter sobre o item')
      local tbuf, twin = open_menu('Templates', t_lines, 60)
      local function close_all_menus()
        for _, w in ipairs(api.nvim_list_wins()) do
          local cfg = api.nvim_win_get_config(w)
          if cfg.relative == 'editor' and cfg.border then
            api.nvim_win_close(w, true)
          end
        end
      end
      local function show_action_menu(name)
        local action_lines = { ' === Ação: ' .. name .. ' ===', '', ' 1. Usar template (substituir buffer)', ' 2. Copiar para clipboard', ' 3. Abrir em split', '', ' q ou Esc para cancelar' }
        local abuf, awin = open_menu('Ação', action_lines, 55)
        vim.keymap.set('n', '1', function()
          local content = fn.readfile(tdir .. '/' .. name)
          api.nvim_buf_set_lines(bufnr, 0, -1, false, content)
          buffer_config_cache[bufnr] = nil
          local new_config = get_buffer_config(bufnr)
          new_config.quarto_id = fn.sha256(api.nvim_buf_get_name(bufnr) .. os.time()):sub(1, 8)
          save_buffer_config(bufnr)
          close_all_menus()
        end, { buffer = abuf })
        vim.keymap.set('n', '2', function()
          fn.setreg('+', table.concat(fn.readfile(tdir .. '/' .. name), '\n'))
          api.nvim_win_close(awin, true)
        end, { buffer = abuf })
        vim.keymap.set('n', '3', function()
          close_all_menus()
          vim.cmd('split ' .. fn.fnameescape(tdir .. '/' .. name))
        end, { buffer = abuf })
        return awin
      end
      -- Keymaps numéricos para templates
      for i = 1, #items do
        vim.keymap.set('n', tostring(i), function()
          local name = items[i]
          show_action_menu(name)
        end, { buffer = tbuf })
      end
      -- Enter sobre o item
      vim.keymap.set('n', '<CR>', function()
        if not api.nvim_win_is_valid(twin) then return end
        local cursor_idx = api.nvim_win_get_cursor(twin)[1]
        local item_idx = cursor_idx - 2
        if item_idx > 0 and item_idx <= #items then
          local name = items[item_idx]
          show_action_menu(name)
        end
      end, { buffer = tbuf })
    end

    local lines = {
      ' === Configurações (salvas no YAML) ===',
      '',
      ' 1. Usar diretório temporário (tmp): ' .. tostring(not config.quarto_usar_local_fisico),
      ' 2. Push de arquivos para Comp: ' .. tostring(config.quarto_push_comp),
      ' 3. Modo Escrita: ' .. tostring(config.quarto_modo_escrita),
      ' 4. Modo Rápido (sem executar código): ' .. tostring(config.quarto_modo_rapido),
      ' 5. Ignorar Ativos: ' .. tostring(config.quarto_ignorar_ativos),
      ' 6. Usar output-file simples: ' .. tostring(config.quarto_outputfile),
      ' 7. Ativos Gerais',
      ' 8. Ativos para Extensões',
      ' 9. Templates',
      '',
      ' Pressione o número ou <Enter> sobre a linha',
    }
    local buf, win = open_menu('Configurações', lines, 75)

    local function update_lines()
      lines[3] = ' 1. Usar diretório temporário (tmp): ' .. tostring(not config.quarto_usar_local_fisico)
      lines[4] = ' 2. Push de arquivos para Comp: ' .. tostring(config.quarto_push_comp)
      lines[5] = ' 3. Modo Escrita: ' .. tostring(config.quarto_modo_escrita)
      lines[6] = ' 4. Modo Rápido (sem executar código): ' .. tostring(config.quarto_modo_rapido)
      lines[7] = ' 5. Ignorar Ativos: ' .. tostring(config.quarto_ignorar_ativos)
      lines[8] = ' 6. Usar output-file simples: ' .. tostring(config.quarto_outputfile)
      api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    end

    local function toggle_quarto_usar_local_fisico()
      config.quarto_usar_local_fisico = not config.quarto_usar_local_fisico
      update_lines()
      save_buffer_config(bufnr)
    end

    local function toggle_quarto_push_comp()
      if config.quarto_usar_local_fisico then
        vim.notify('Push só está disponível quando usando diretório tmp.', vim.log.levels.WARN)
        return
      end
      config.quarto_push_comp = not config.quarto_push_comp
      update_lines()
      save_buffer_config(bufnr)
    end

    local function toggle(key)
      config[key] = not config[key]
      update_lines()
      save_buffer_config(bufnr)
      if key == 'quarto_modo_escrita' and preview_state.mode == 'compile' and preview_state.bufnr == bufnr then
        refresh_preview()
      end
    end

    vim.keymap.set('n', '1', toggle_quarto_usar_local_fisico, { buffer = buf })
    vim.keymap.set('n', '2', toggle_quarto_push_comp, { buffer = buf })
    vim.keymap.set('n', '3', function() toggle 'quarto_modo_escrita' end, { buffer = buf })
    vim.keymap.set('n', '4', function() toggle 'quarto_modo_rapido' end, { buffer = buf })
    vim.keymap.set('n', '5', function() toggle 'quarto_ignorar_ativos' end, { buffer = buf })
    vim.keymap.set('n', '6', function() toggle 'quarto_outputfile' end, { buffer = buf })
    vim.keymap.set('n', '7', open_gerais, { buffer = buf })
    vim.keymap.set('n', '8', open_extensoes, { buffer = buf })
    vim.keymap.set('n', '9', open_templates, { buffer = buf })

    vim.keymap.set('n', '<CR>', function()
      local cursor = api.nvim_win_get_cursor(win)[1]
      if cursor == 3 then toggle_quarto_usar_local_fisico()
      elseif cursor == 4 then toggle_quarto_push_comp()
      elseif cursor == 5 then toggle 'quarto_modo_escrita'
      elseif cursor == 6 then toggle 'quarto_modo_rapido'
      elseif cursor == 7 then toggle 'quarto_ignorar_ativos'
      elseif cursor == 8 then toggle 'quarto_outputfile'
      elseif cursor == 9 then open_gerais()
      elseif cursor == 10 then open_extensoes()
      elseif cursor == 11 then open_templates()
      end
    end, { buffer = buf })
    return
  end

  vim.notify('Comando desconhecido. Use :Quarto -h', vim.log.levels.WARN)
end

api.nvim_create_user_command('Quarto', quarto_handler, { nargs = '*' })

-- =========================================================================
--  KEYMAPS UNIFICADOS (agora com prefixo <leader>t)
-- =========================================================================
local function setup_which_key()
  local ok, wk = pcall(require, 'which-key')
  if not ok then return end

  local runner_ok, runner = pcall(require, 'quarto.runner')

  wk.add {
    { '<leader>th', '<cmd>Quarto -h<CR>', desc = 'Ajuda Quarto' },
    { '<leader>tp', group = 'Preview' },
    { '<leader>tph', '<cmd>Quarto -p html<CR>', desc = 'HTML' },
    { '<leader>tpp', '<cmd>Quarto -p pdf<CR>', desc = 'PDF' },
    { '<leader>tr', '<cmd>Quarto -r<CR>', desc = 'Atualizar preview' },
    { '<leader>tk', '<cmd>Quarto -k<CR>', desc = 'Parar preview' },
    { '<leader>tc', group = 'Renderizar' },
    { '<leader>tch', '<cmd>Quarto -c html<CR>', desc = 'HTML' },
    { '<leader>tcp', '<cmd>Quarto -c pdf<CR>', desc = 'PDF' },
    { '<leader>tb', '<cmd>Quarto -b<CR>', desc = 'Blocos' },
    { '<leader>tm', '<cmd>Quarto -m<CR>', desc = 'Configurações' },
    { '<leader>tl', '<cmd>Quarto -l<CR>', desc = 'Logs' },
  }

  if runner_ok then
    wk.add {
      { '<leader>rc', runner.run_cell, desc = 'run cell' },
      { '<leader>ra', runner.run_above, desc = 'run cell and above' },
      { '<leader>rA', runner.run_all, desc = 'run all cells (same lang)' },
      { '<leader>rl', runner.run_line, desc = 'run line' },
      { '<leader>r', runner.run_range, mode = 'v', desc = 'run visual range' },
    }
  end
end

-- =========================================================================
--  Autocmds
-- =========================================================================
api.nvim_create_autocmd('InsertLeave', {
  group = quarto_group,
  pattern = { '*.qmd', '*.md', '*.Rmd', '*.rmd' },
  callback = function(ev)
    if not is_supported_extension(ev.buf) then return end
    if preview_state.mode == 'compile' and preview_state.bufnr == ev.buf then
      refresh_preview()
    else
      update_shadow_from_buffer(ev.buf)
    end
  end,
})

api.nvim_create_autocmd('BufWritePost', {
  group = quarto_group,
  pattern = { '*.qmd', '*.md', '*.Rmd', '*.rmd' },
  callback = function(ev)
    if not is_supported_extension(ev.buf) then return end
    update_shadow_from_buffer(ev.buf)
    if preview_state.mode == 'compile' and preview_state.bufnr == ev.buf then
      refresh_preview()
    end
  end,
})

api.nvim_create_autocmd('VimLeavePre', {
  group = quarto_group,
  callback = function()
    stop_preview()
    -- Garante limpeza de perfil residual
    if preview_state.browser_temp_profile then
      fn.system("rm -rf " .. preview_state.browser_temp_profile .. " 2>/dev/null")
    end
  end,
})

vim.schedule(setup_which_key)
