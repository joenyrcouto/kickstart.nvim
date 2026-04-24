# 🚀 Obsidian + Neovim: Integração Híbrida (Dotfile para o pseudo init)

Esta configuração permite que o Neovim e o Obsidian funcionem como uma única ferramenta. O Neovim atua como o motor de navegação e edição avançada, enquanto o Obsidian cuida da interface gráfica e renderização.

https://github.com/user-attachments/assets/2c91e83f-e74b-44c7-96d7-2ac39bcf7ace

## 📂 Onde colocar cada arquivo

Para que a integração funcione, os arquivos/pasta deste repositório devem ser distribuídos nos seguintes endereços do seu sistema:

| Arquivo | Destino | Função |
| :--- | :--- | :--- |
| `start-nvim-obsidian.sh` | Qualquer | Script que limpa a porta 2006 e inicia o servidor Neovim. |
| `init.lua` (Pseudo-Config) | `~/.config/nvim-obsidian/` | Perfil isolado que ativa a ponte e herda sua config Master. |
| `*.css` | `[Vault]/.obsidian/snippets/` | Snippets CSS para a interface responsiva (gaveta). |
| `edit-in-neovim-modificado` | `[Vault]/.obsidian/plugins/` | Plugin que sicroniza o buffer do obsidian para o neovim. |

---

## 🔧 Configuração no Obsidian

Após mover os arquivos/pasta, siga estes passos dentro do Obsidian:

### 1. Ativar o Visual (CSS)
1. Vá em `Settings` -> `Appearance`.
2. Role até **CSS Snippets**.
3. Ative o interruptor dos arquivos `*.css`.
   - *Isso removerá as abas do terminal e fará com que ele expanda automaticamente ao ser focado (coloque uma tecla para o atalho da opção de troca de foco que o próprio plugin Terminal disponibiliza).*

### 2. Configurar o Servidor (Plugin: Terminal)
1. Vá em `Settings` -> `Terminal` -> `Profiles`.
2. No seu perfil (ex: `bridge-nvim`), configure:
   - **Executable:** `[qualquer]/start-nvim-obsidian.sh` (Use o caminho completo e substitua [qualquer] pelo caminho que você deixou).
   - **Arguments:** Deixe a lista vazia.
3. Defina ele como default, na página principal do puglin.
4. Extra: baixe uma fonte Nerd no seu sistema e configure ela no seu perfil (garante o uso de fontes nerds no peseudo init do neovim, tem uma chave de true e false nele).

### 3. Configurar o Controle (Plugin: Edit in Neovim — modificado)
1. Vá em `Settings` -> `Edit in Neovim`.
2. Configure conforme abaixo:
   - **NVIM_APPNAME:** `nvim-obsidian`
   - **Neovim server location:** `127.0.0.1:2006`
   - **Open on startup:** `OFF` (O plugin Terminal gerencia o boot).

Obs: certifique de ter uma chave salva no ambiente, como é explicado pelo [edit-in-neovim](https://github.com/TheseusGrey/edit-in-neovim).

---

## ⚙️ Configuração no init principal

Insira, este bloco abaixo, na configuração real do seu init: ([aqui](https://github.com/joenyrcouto/NVIM-optimized-for-academy/blob/master/init.lua) tem um exemplo de uso)

```
-- =============================================================================
-- PONTE OBSIDIAN - PROTEÇÃO DE ESTADO (ANTI-LOOP)
-- =============================================================================

local last_sync_path = "" -- Variável de controle para evitar duplicidade

local function sync_to_obsidian()
    if not vim.g.launched_from_obsidian then return end
    
    local filepath = vim.fn.expand("%:p"):gsub("\\", "/"):lower()
    local bufnr = vim.api.nvim_get_current_buf()
    
    -- 1. Filtros de segurança
    if vim.bo[bufnr].buftype ~= "" or filepath == "" then return end
    if not (filepath:find("%.md$") or filepath:find("%.qmd$") or filepath:find("%.base$")) then return end

    -- 2. Verifica a trava vinda do Obsidian (impede o loop de volta)
    local lock_path = (vim.g.obsidian_lock or ""):gsub("\\", "/"):lower()
    if lock_path ~= "" and filepath == lock_path then
        vim.g.obsidian_lock = "" 
        last_sync_path = filepath -- Registra que o Obsidian já sabe deste arquivo
        return 
    end

    -- 3. Evita enviar a notificação se o arquivo for o mesmo que acabamos de sincronizar
    if filepath == last_sync_path then return end

    -- 4. Execução (Ação manual do usuário no Neovim)
    last_sync_path = filepath
    local raw_path = vim.fn.expand("%:p")
    local encoded_path = raw_path:gsub(" ", "%%20")
    
    -- Adicionamos o parâmetro silent=true (se o plugin do Obsidian suportar) 
    -- ou simplesmente limpamos o log.
    local uri = "obsidian://open?path=" .. encoded_path

    if vim.fn.has("unix") == 1 then
        vim.fn.jobstart({"xdg-open", uri}, { detach = true })
    elseif vim.fn.has("win32") == 1 then
        vim.fn.jobstart({"cmd.exe", "/c", "start", uri}, { detach = true })
    end
end

local obsidian_sync_group = vim.api.nvim_create_augroup("ObsidianSync", { clear = true })
vim.api.nvim_create_autocmd("BufEnter", {
    group = obsidian_sync_group,
    pattern = { "*.md", "*.qmd", "*.base" },
    callback = function()
        -- schedule garante que variáveis globais enviadas por RPC já foram processadas
        vim.schedule(sync_to_obsidian)
    end
})

-- =============================================================================
```

---

## ⚠️ Notas Importantes para Linux (foi feito para uso nele, adapte ao seu sistema, se necessário)
- **Permissões:** Certifique-se de que o script de inicialização é executável:
  ```bash
  chmod +x ~/start-nvim-obsidian.sh
  ```
- **Dependências:** O script utiliza `fuser` e `lsof` para gerenciar a porta 2006. Instale-os via pacman:
  ```bash
  sudo pacman -S psmisc lsof
  ```
- **Nerd Fonts:** A pseudo-configuração desativa Nerd Fonts no terminal integrado para manter o visual limpo em janelas pequenas, enquanto sua configuração Master (`nvim`) continuará com ícones normais quando aberta fora do Obsidian.
