
**Shadow (RAM):** `/tmp/nvim_quarto_shadow/<id>/` – cada buffer recebe um ID único (hash do caminho + timestamp) persistido no YAML.

---

## ⌨️ Comandos e Atalhos

### Comando principal: `:Quarto [flag] [opções]`

| Flag / Exemplo                     | Descrição                                                                                |
|------------------------------------|------------------------------------------------------------------------------------------|
| `:Quarto -h`                       | Exibe menu de ajuda (atalho `<leader>th`)                                                 |
| `:Quarto -p [html\|pdf]`           | Preview **rápido** (código não executado). Atualiza ao sair do Insert.                    |
| `:Quarto -p -c [html\|pdf]`        | Preview **compilado** (executa blocos). Atualiza somente com `:Quarto -r`.                |
| `:Quarto -p -s ...`                | Força salvamento do resultado mesmo em caso de erro (experimental).                       |
| `:Quarto -r`                       | Atualiza manualmente o preview ativo.                                                     |
| `:Quarto -k`                       | Para o servidor de preview.                                                               |
| `:Quarto -c [pdf\|html]`           | Renderização final. Salva conforme configuração de `comp_nativa`.                         |
| `:Quarto -c -s ...`                | Força salvamento mesmo com erro de compilação.                                            |
| `:Quarto -b`                       | Lista blocos de código; pergunta se quer **enviar ao REPL** ou **copiar para clipboard** (se `vim-slime` disponível). |
| `:Quarto -l`                       | Abre visualização de logs (preview ou render).                                            |
| `:Quarto -m`                       | Menu de configurações (modos, ativos, extensões, templates).                              |

### Atalhos do Plugin Otimizado (prefixo `<leader>t`)

| Atalho        | Ação                                                    |
|---------------|---------------------------------------------------------|
| **Quarto Otimizado (`<leader>t`)** |                                                         |
| `<leader>th`  | Ajuda (`:Quarto -h`)                                    |
| `<leader>tp`  | Menu de Preview                                         |
| `<leader>tpf` | Preview rápido HTML                                     |
| `<leader>tpc` | Preview compilado PDF                                   |
| `<leader>tph` | Preview compilado HTML                                  |
| `<leader>tr`  | Atualizar preview                                       |
| `<leader>tk`  | Parar preview                                           |
| `<leader>tc`  | Menu de Renderização                                    |
| `<leader>tcp` | Renderizar PDF                                          |
| `<leader>tch` | Renderizar HTML                                         |
| `<leader>tb`  | Executar bloco de código (menu interativo)              |
| `<leader>tm`  | Abrir configurações                                     |
| `<leader>tl`  | Ver logs                                                |

### Atalhos do Runner de Células (prefixo `<leader>r`)

| Atalho        | Ação                                                    |
|---------------|---------------------------------------------------------|
| `<leader>rc`  | Executar célula atual                                   |
| `<leader>ra`  | Executar célula atual e acima                           |
| `<leader>rA`  | Executar todas as células (mesma linguagem)             |
| `<leader>rl`  | Executar linha atual                                    |
| `<leader>r`   | Executar seleção visual (modo visual)                   |
| `<leader>RA`  | Executar todas as células (todas as linguagens)         |

### Atalhos Globais Adicionais

| Atalho        | Ação                                                                                      |
|---------------|-------------------------------------------------------------------------------------------|
| `Shift+Enter` | Em arquivos Quarto/Julia/Python/R/bash: executa a célula atual. Caso contrário, exibe uma mensagem informativa. |

---

## 🗺️ Atalhos Personalizados do `config.keymap.lua`

Estes atalhos foram herdados de uma configuração prévia e complementam o fluxo Quarto/R/Python. Eles usam principalmente `<leader>q`, `<leader>o`, `<leader>c` e combinações com `Ctrl/Alt`.

### Quarto Nativo (`<leader>q`)

| Atalho        | Ação                                                     |
|---------------|----------------------------------------------------------|
| `<leader>qp`  | Iniciar preview do Quarto                                |
| `<leader>qu`  | Atualizar preview                                        |
| `<leader>qq`  | Fechar preview silenciosamente                           |
| `<leader>qa`  | Ativar Quarto no buffer atual                            |
| `<leader>qe`  | Exportar blocos de código (otter)                        |
| `<leader>qE`  | Exportar sobrescrevendo arquivos existentes              |
| `<leader>qh`  | Ajuda do Quarto                                          |
| `<leader>qrr` | Executar células acima do cursor                         |
| `<leader>qrb` | Executar células abaixo do cursor                        |
| `<leader>qra` | Executar todas as células                                |

### Inserção de Blocos de Código (`<leader>o` e modificadores)

| Atalho        | Ação                                          |
|---------------|-----------------------------------------------|
| `<leader>or`  | Inserir bloco R (` ```{r} `)                  |
| `<leader>op`  | Inserir bloco Python (` ```{python} `)        |
| `<leader>oj`  | Inserir bloco Julia (` ```{julia} `)          |
| `<leader>ob`  | Inserir bloco Bash (` ```{bash} `)            |
| `<leader>ol`  | Inserir bloco Lua (` ```{lua} `)              |
| `<leader>oo`  | Inserir bloco Observable JS (` ```{ojs} `)    |
| `<leader>Or`  | Inserir bloco R sem chaves (` ```r `)         |
| `<leader>Op`  | Inserir bloco Python sem chaves (` ```python `)|
| `...`         | (demais linguagens com `O` maiúsculo)          |
| `<M-i>`       | (modo normal/inserção) Inserir bloco R        |
| `<M-I>`       | (modo normal/inserção) Inserir bloco Python   |

### Execução de Código

| Atalho               | Modo         | Ação                                                            |
|----------------------|--------------|-----------------------------------------------------------------|
| `<C-CR>` / `<S-CR>`  | Normal/Inserção | Enviar célula atual para o REPL (via slime ou Molten)          |
| `<CR>`               | Visual       | Enviar seleção visual para o REPL                               |
| `<leader><CR>`       | Normal       | Idem ao `<C-CR>`                                                |
| `<leader>rt`         | Normal       | Mostrar tabela R sob o cursor no navegador (requer DT)          |

### Terminais e REPLs (`<leader>c`)

| Atalho        | Ação                                       |
|---------------|--------------------------------------------|
| `<leader>cr`  | Abrir terminal vertical com R              |
| `<leader>cp`  | Abrir terminal vertical com Python         |
| `<leader>cj`  | Abrir terminal vertical com Julia          |
| `<leader>ci`  | Abrir terminal vertical com IPython        |
| `<leader>cn`  | Abrir terminal vertical com shell padrão   |

### Navegação e Janelas

| Atalho                          | Modo   | Ação                                               |
|---------------------------------|--------|----------------------------------------------------|
| `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>` | Normal | Mover foco entre janelas                           |
| `<S-Up>`, `<S-Down>`, `<S-Left>`, `<S-Right>` | Normal | Redimensionar janela atual (±2 linhas/colunas)    |
| `H` / `L`                       | Normal | Alternar para aba anterior / próxima               |
| `n`                             | Normal | Próxima busca **+ centralizar**                    |
| `gN`                            | Normal | Busca anterior **+ centralizar**                   |

### Edição e Salvamento

| Atalho        | Modo         | Ação                                                    |
|---------------|--------------|---------------------------------------------------------|
| `<C-s>`       | Normal/Inserção | Salvar arquivo (`:update`)                            |
| `gV`          | Normal       | Selecionar último texto colado                          |
| `>` / `<`     | Visual       | Indentar / remover indentação (mantém seleção)          |
| `<leader>d`   | Visual       | Deletar sem sobrescrever registro                       |
| `<leader>p`   | Visual       | Substituir sem sobrescrever registro                    |

### LSP e Ferramentas

| Atalho        | Ação                                                     |
|---------------|----------------------------------------------------------|
| `<leader>ldd` | Desabilitar diagnósticos                                 |
| `<leader>lde` | Habilitar diagnósticos                                   |
| `<leader>le`  | Exibir erro/diagnóstico sob o cursor em janela flutuante |
| `<leader>lg`  | Gerar docstring (Neogen)                                 |
| `<leader>os`  | Listar símbolos do Otter por linguagem                   |

### Git

| Atalho        | Ação                                           |
|---------------|------------------------------------------------|
| `<leader>gg`  | Abrir painel do Lazygit                        |
| `<leader>gs`  | Abrir painel do Gitsigns                       |
| `<leader>gb`  | Git Blame (toggle, copy URL, open URL)         |
| `<leader>gc`  | Atualizar conflitos (GitConflict)              |

### Busca com Telescope (`<leader>f`)

| Atalho         | Ação                                    |
|----------------|-----------------------------------------|
| `<leader>ff`   | Localizar arquivos                      |
| `<leader>fg`   | Busca por texto (live grep)             |
| `<leader>fb`   | Busca difusa no buffer atual            |
| `<leader>fh`   | Tags de ajuda                           |
| `<leader>fk`   | Lista de keymaps                        |
| `<leader>fd`   | Lista de buffers abertos                |
| `<leader>fM`   | Páginas de manual                       |

### Outros Úteis

| Atalho        | Ação                                                     |
|---------------|----------------------------------------------------------|
| `<leader>vt`  | Alternar tema claro/escuro                               |
| `<leader>vs`  | Editar `init.lua` e abrir diretório de configuração      |
| `<leader>hc`  | Alternar nível de ocultação (conceallevel)               |
| `<leader>ic`  | Limpar cache de imagens (snacks.nvim)                    |
| `<leader>xx`  | Salvar e recarregar o arquivo atual (`:source %`)        |

> **Nota:** Muitos desses atalhos aparecem no menu do `which-key` quando você pressiona `<leader>` e aguarda.

---

## 🧠 Mecanismo de Shadow e Configuração YAML

- Cada buffer `.qmd`/`.md` recebe um **ID único** (`quarto_id`) gerado na primeira operação de preview/render e salvo no frontmatter YAML.
- O diretório shadow é `/tmp/nvim_quarto_shadow/<id>/`. Nele são mantidos:
  - Cópia atualizada do conteúdo do buffer (sincronizada a cada `InsertLeave` e `BufWritePost`).
  - Ativos copiados conforme configuração (gerais e extensões).
- A **renderização** (`:Quarto -c`) pode ocorrer:
  - No **shadow** (padrão) – mais rápida, ideal para testes.
  - No **diretório físico original** se `quarto_usar_local_fisico = true` (útil para builds finais com estrutura estável).
- Após renderização bem‑sucedida, o arquivo de saída é copiado para:
  - `~/Documents/Quarto/Comp/<id>/` se `comp_nativa = false`
  - Pasta original do arquivo se `comp_nativa = true`

---

## ⚙️ Menu de Configurações (`:Quarto -m`)

| Opção | Descrição                                                                 |
|-------|----------------------------------------------------------------------------|
| **1. Compilação Nativa** | Se `true`, salva resultado da renderização na pasta original do arquivo.  |
| **2. Modo Escrita**      | (Reservado para uso futuro – atualmente não afeta comportamento).         |
| **3. Usar Local Físico** | Se `true`, renderização (`-c`) ocorre no diretório do arquivo (sem shadow).|
| **4. Ignorar Ativos**    | Se `true`, não copia gerais nem extensões durante compilação.              |
| **5. Ativos Gerais**     | Seleciona quais itens de `~/Documents/Quarto/Gerais/` serão copiados.      |
| **6. Extensões**         | Seleciona quais extensões (pastas em `~/Documents/Quarto/Extens/`) serão copiadas para `_extensions/`. |
| **7. Templates**         | Lista arquivos de `~/Documents/Quarto/temp/` para **Usar** (substitui buffer) ou **Copiar** (clipboard). |

> Todas as alterações são salvas imediatamente no YAML do buffer.

---

## ✅ Checklist de Funcionalidades (para validação)

Marque conforme testar:

- [ ] **Shadow em RAM**: Preview e render usam `/tmp`, não disco (exceto se `usar_local_fisico` ativo).
- [ ] **Atualização automática (modo rápido)**: Ao sair do Insert, preview HTML é atualizado sem intervenção.
- [ ] **Preview compilado**: Com `-c`, executa código e só atualiza com `:Quarto -r`.
- [ ] **Comando `:Quarto -r`**: Força atualização do preview ativo.
- [ ] **Parada do servidor**: `:Quarto -k` mata o processo do Quarto.
- [ ] **Renderização final (`-c`)**: Gera PDF/HTML e abre automaticamente.
- [ ] **Forçar salvamento (`-s`)**: Mesmo com erro, o arquivo de saída é mantido/copiado.
- [ ] **Execução de blocos (`-b`)**: Lista blocos, oferece escolha entre enviar ao REPL (se slime disponível) ou copiar.
- [ ] **Visualização de logs (`-l`)**: Abre split com log de preview ou render.
- [ ] **Configurações (`-m`)**: Menu interativo altera toggles e ativos; mudanças persistem no YAML.
- [ ] **Persistência do ID**: `quarto_id` no YAML mantém a mesma pasta shadow entre sessões.
- [ ] **Sincronização de Gerais**: Pastas/arquivos selecionados são copiados para raiz da compilação.
- [ ] **Sincronização de Extensões**: Pastas selecionadas são copiadas para `_extensions/`.
- [ ] **Templates**: Substituir buffer ou copiar conteúdo de template.
- [ ] **Atalhos which-key**: Todos os mapeamentos `<leader>t...` e `<leader>r...` funcionam.
- [ ] **Ignorar ativos**: Com toggle ativo, nenhum ativo extra é copiado.
- [ ] **Shift+Enter**: Em arquivos suportados, executa a célula; fora deles, exibe notificação amigável.
- [ ] **LSP condicional**: `julials` e outros servidores só iniciam nos filetypes configurados.

---

## 🔧 Dependências Recomendadas

- [Quarto CLI](https://quarto.org/docs/get-started/)
- [vim-slime](https://github.com/jpalardy/vim-slime) (para `:Quarto -b`)
- [which-key.nvim](https://github.com/folke/which-key.nvim) (para atalhos)
- [otter.nvim](https://github.com/jmbuhr/otter.nvim) (já incluso como dependência do quarto-nvim)

---

## 🚀 Instalação

Antes vale mencionar que o setup foi feito para sistema Linux, onde os discos são montados em árvore e temos o diretório `/tmp` que é um tmpfs (adeque a configuração para funcionar no seu sistema operacional).

Faça um fork do repositório e clone no seu `~/.config/nvim/`. Ou simplesmente clone direto.

Certifique-se de que os diretórios `~/Documents/Quarto/{Comp,Gerais,Extens,temp}` existam (ou serão criados automaticamente).

---

## 🔗 Links que auxiliaram na construção do dotfile

- [Neovim](https://github.com/neovim) (onde configurei o neovim limpo do zero e implementei lsp)
- [Aman9das/quarto-nvim-dotfiles](https://github.com/Aman9das/quarto-nvim-dotfiles) (exportei e atualizei algumas funções para a nova sintaxe do neovim)
- [quarto-dev/quarto-nvim](https://github.com/quarto-dev/quarto-nvim) (importante para entender funcionamento do Quarto, dependências etc)
- [jmbuhr/otter.nvim](https://github.com/jmbuhr/otter.nvim) (parte responsável por modular o lsp junto com o autocomplete, de escolha, nos blocos)
- Além de outras pesquisas...

---

**Divirta-se estudando e produzindo com velocidade!** 🚀
