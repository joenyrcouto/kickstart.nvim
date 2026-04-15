# 🚀 Neovim Acadêmico: Quarto + Obsidian + Zettelkasten (Beta em teste)

*Configuração pessoal do Neovim otimizada para pesquisa, estudo e escrita técnica. Integra **Obsidian** (gestão de notas), **Quarto** (publicação científica) e **Inteligência Artificial local**, com previews acelerados por **Shadow Sync em RAM** (`/tmp`).*

> **Shadow (RAM):** `/tmp/nvim_quarto_shadow/<id>/` – cada buffer recebe um ID único salvo no YAML.

---

## 📖 Fluxos principais (resumo)

### 🧠 Obsidian Vault (obsidian.nvim)
- Vault em `~/Documents/brain`.
- `<Enter>` segue links `[[...]]`. Templates em `content/99-brutos/Templates`.
- Tem o plugin  `obsidian-bridge.nvim`. Configure o [edit-in-neovim](https://github.com/TheseusGrey/edit-in-neovim) no seu app do Obsidian.

### ⚡ Quarto Shadow System
- `:Quarto -p` copia o buffer para `/tmp` e inicia preview **sem tocar no disco**.
- Modo **rápido** (padrão) atualiza ao sair do Insert; modo **compilado** (`-c`) executa código e só atualiza com `:Quarto -r`.
- Menu `:Quarto -m` gerencia ativos, extensões e templates.
- Atalhos dedicados na tecla `<leader>t`, veja mais em [`QUARTO_SHADOW.md`](./QUARTO_SHADOW.md).

### 🐙 Github CLI + Lazygit + Gitsins + Git‑bug
- Integração e automatização de ferramentas, com criação, edição e consulta de issues **totalmente offline**, com sincronização posterior.
- Atalhos dedicados na tecla `<leader>g`, veja mais em [`GITBUG.md`](./GITHUB.md).

### 🤖 IA Local (CodeCompanion + LM Studio)
- Modelos como Gemma ou Llama rodando localmente via LM Studio.
- Atalhos dedicados na tecla `<leader>c`, veja mais em [`IA.md`](./IA.md).

---

## ⌨️ Atalhos essenciais

### Edição
| Atalho        | Ação                                                    |
|---------------|---------------------------------------------------------|
| `<C-s>`       | Salvar arquivo (`:update`)                              |
| `<C-S-K>`     | Excluir arquivo atual (com confirmação)                 |
| `<leader>rn`  | Renomear arquivo físico no disco                        |
| `<leader>e`   | Abrir explorador de arquivos (Neo-tree)                 |
| `u`           | Desfazer última alteração                               |
| `<C-r>`       | Refazer alteração desfeita                              |
| `<leader>v`   | Dividir janela verticalmente (`:vsp`)                   |
| `<leader>h`   | Dividir janela horizontalmente (`:sp`)                  |
| `<A-h>`       | Alternar terminal horizontal (toggle)                   |
| `<A-v>`       | Alternar terminal horizontal (toggle)                   |
| `<A-i>`       | Alternar terminal com permanencia flutuante (toggle)    |
| `<leader>oj`  | Inserir bloco de código Julia (` ```{julia} `)          |

### Quarto Otimizado (`<leader>t`)
| Atalho | Ação |
|--------|------|
| `<leader>th` | Ajuda |
| `<leader>tpf` / `tpc` / `tph` | Preview rápido / compilado (HTML/PDF) |
| `<leader>tr` | Atualizar preview |
| `<leader>tk` | Parar preview |
| `<leader>tcp` / `tch` | Renderizar PDF / HTML |
| `<leader>tb` | Executar bloco de código |
| `<leader>tm` | Configurações |
| `<leader>tl` | Ver logs |

### Git‑Bug (`<leader>g`)
| Atalho | Ação |
|--------|------|
| `<leader>ga` | Nova issue (janela flutuante) |
| `<leader>gl` | Interface TUI (Kitty float) |
| `<leader>gp` | Sincronizar (push/pull) |
| `<leader>gu` | Gerenciar identidades (criar/selecionar) |
| `<leader>gz` | Configurar bridge com GitHub (usa token do `gh`) |
| `<leader>gk` | Gerenciar keyrings (limpar todas ou específica) |

### IA (CodeCompanion)
| Atalho | Modo | Ação |
|--------|------|------|
| `<leader>ca` | n/v | Menu de ações |
| `<leader>cc` | n/v | Alternar chat |
| `<leader>ci` | n/v | Prompt inline |
| `ga` | v | Adicionar seleção ao chat |

### Outros grupos importantes 
- **Runner de células** (`<leader>r`) → `rc`, `ra`, `rA`, `rl`, `r`, `RA`
- **Telescope** (`<leader>f`) → `ff`, `fg`, `fb`, `fh`, `fk`, etc.
- **LSP / Diagnóstico** (`<leader>l`) → `ldd`, `lde`, `le`, `lg`
- **Git** (`<leader>g`) → `gg` (LazyGit), `gs` (Gitsigns), `gl` (Git-bug termui)

> 📘 Lista completa de atalhos em [`KEYMAPS.md`](./KEYMAPS.md).

---

## 📂 Estrutura de diretórios esperada

```
Documents/
├── brain/                     # Vault Obsidian
└── Quarto/
    ├── Extens/                # _extensions
    ├── Gerais/                # Ativos copiados para raiz
    ├── Temp/                  # Templates
    └── Comp/                  # Destino dos renders (shadow)
```

---

## 🧪 Configuração rápida

1. Clone este repositório em `~/.config/nvim`.
2. Instale as dependências: `Lazygit`, `Git-bug`, `Github CLI`, `Quarto CLI`, `vim-slime`, `gh` e `nvr`.
3. Configure o Kitty para remote control (necessário para `<leader>gl`).
4. Inicie o LM Studio com um modelo e ajuste a URL/porta no bloco do CodeCompanion.

---

## 🔗 Principais referências

- [Neovim](https://github.com/neovim) · [quarto-nvim](https://github.com/quarto-dev/quarto-nvim) · [otter.nvim](https://github.com/jmbuhr/otter.nvim)
- [codecompanion.nvim](https://github.com/olimorris/codecompanion.nvim) · [git‑bug](https://github.com/MichaelMure/git-bug) · [edit-in-neovim](https://github.com/TheseusGrey/edit-in-neovim) 

---

**Divirta-se estudando e produzindo com velocidade!** 🚀
