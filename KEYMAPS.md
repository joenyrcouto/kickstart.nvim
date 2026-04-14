# ⌨️ Atalhos Completos – Neovim Acadêmico

Este documento lista todos os atalhos configurados no `config.keymap.lua` e nos plugins personalizados. Use `<leader>` como `Espaço`.

## 🧭 Navegação e Janelas

| Atalho                     | Modo   | Ação                                          |
|----------------------------|--------|-----------------------------------------------|
| `<C-h/j/k/l>`              | Normal | Mover foco entre janelas                      |
| `<S-Up/Down/Left/Right>`   | Normal | Redimensionar janela (±2 linhas/colunas)      |
| `H` / `L`                  | Normal | Aba anterior / próxima                        |
| `<leader><leader>`         | Normal | Listar buffers abertos (Telescope)            |

## ✏️ Edição

| Atalho        | Modo         | Ação                                          |
|---------------|--------------|-----------------------------------------------|
| `<C-s>`       | Normal/Insert| Salvar (`:update`)                            |
| `<C-S-K>`     | Normal       | Excluir arquivo (`:!rm %`)                    |
| `gV`          | Normal       | Selecionar último texto colado                |
| `>` / `<`     | Visual       | Indentar / remover indentação (mantém seleção)|
| `<leader>d/p` | Visual       | Deletar/substituir sem sobrescrever registro  |

## 🔍 Telescope (`<leader>f`)

| Atalho | Ação                       |
|--------|----------------------------|
| `ff`   | Localizar arquivos         |
| `fg`   | Live grep                  |
| `fb`   | Busca difusa no buffer     |
| `fh`   | Tags de ajuda              |
| `fk`   | Lista de keymaps           |
| `fd`   | Lista de buffers           |
| `fM`   | Páginas de manual          |

## 🧪 Quarto Otimizado (`<leader>t`)

| Atalho | Ação                              |
|--------|-----------------------------------|
| `th`   | Ajuda                             |
| `tpf`  | Preview rápido HTML               |
| `tpc`  | Preview compilado PDF             |
| `tph`  | Preview compilado HTML            |
| `tr`   | Atualizar preview                 |
| `tk`   | Parar preview                     |
| `tcp`  | Renderizar PDF                    |
| `tch`  | Renderizar HTML                   |
| `tb`   | Executar bloco (menu interativo)  |
| `tm`   | Configurações                     |
| `tl`   | Ver logs                          |

## 🏃 Runner de Células (`<leader>r`)

| Atalho | Ação                                          |
|--------|-----------------------------------------------|
| `rc`   | Executar célula atual                         |
| `ra`   | Executar célula atual e acima                 |
| `rA`   | Executar todas as células (mesma linguagem)   |
| `rl`   | Executar linha atual                          |
| `r`    | Executar seleção visual (modo visual)         |
| `RA`   | Executar todas as células (todas linguagens)  |

## 🐙 Git‑Bug (`<leader>g`)

| Atalho | Ação                                          |
|--------|-----------------------------------------------|
| `ga`   | Nova issue (janela flutuante)                 |
| `gl`   | Interface TUI (Kitty float)                   |
| `gp`   | Sincronizar (push/pull)                       |
| `gi`   | Init de bugs tracker                          |
| `gu`   | Adotar/criar identidade                       |

## 🤖 IA – CodeCompanion

| Atalho | Modo         | Ação                                          |
|--------|--------------|-----------------------------------------------|
| `ca`   | n/v          | Menu de ações                                 |
| `cc`   | n/v          | Alternar chat                                 |
| `ci`   | n/v          | Prompt inline                                 |
| `ga`   | v            | Adicionar seleção ao chat                     |

## 🧰 LSP e Ferramentas

| Atalho  | Ação                                          |
|---------|-----------------------------------------------|
| `ldd`   | Desabilitar diagnósticos                      |
| `lde`   | Habilitar diagnósticos                        |
| `le`    | Exibir erro flutuante                         |
| `lg`    | Gerar docstring (Neogen)                      |
| `os`    | Listar símbolos do Otter por linguagem        |

## 🎨 Outros

| Atalho  | Ação                                          |
|---------|-----------------------------------------------|
| `vt`    | Alternar tema claro/escuro                    |
| `vs`    | Editar `init.lua`                             |
| `hc`    | Alternar nível de ocultação (conceallevel)    |
| `ic`    | Limpar cache de imagens                       |
| `xx`    | Salvar e recarregar arquivo atual (`:source %`)|

> **Nota:** Muitos atalhos aparecem no menu do `which-key` ao pressionar `<leader>`.
