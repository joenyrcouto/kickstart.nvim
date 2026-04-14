# 🚀 Neovim Acadêmico: Quarto + Obsidian + Zettelkasten (Beta em teste)

*Configuração pessoal do Neovim otimizada para pesquisa, estudo e escrita técnica. Integra **Obsidian** (gestão de notas), **Quarto** (publicação científica) e **Inteligência Artificial local**, com previews acelerados por **Shadow Sync em RAM** (`/tmp`).*

> **Shadow (RAM):** `/tmp/nvim_quarto_shadow/<id>/` – cada buffer recebe um ID único salvo no YAML.

---

## 📖 Fluxos principais (resumo)

### 🧠 Obsidian Vault
- Vault em `~/Documents/brain`.
- `<Enter>` segue links `[[...]]`. Templates em `content/99-brutos/Templates`.

### ⚡ Quarto Shadow System
- `:Quarto -p` copia o buffer para `/tmp` e inicia preview **sem tocar no disco**.
- Modo **rápido** (padrão) atualiza ao sair do Insert; modo **compilado** (`-c`) executa código e só atualiza com `:Quarto -r`.
- Menu `:Quarto -m` gerencia ativos, extensões e templates.

### 🐙 Git offline + Issues (git‑bug)
- Criação, edição e consulta de issues **totalmente offline**, com sincronização posterior.
- Atalhos dedicados: `<leader>ga` (nova issue em janela flutuante), `<leader>gl` (interface TUI no Kitty), `<leader>gp` (push/pull).

### 🤖 IA Local (CodeCompanion + LM Studio)
- Modelos como Gemma ou Llama rodando localmente via LM Studio.
- Chat (`<leader>cc`), prompt inline (`<leader>ci`) e ações contextuais (`<leader>ca`).

---

## ⌨️ Atalhos essenciais (consulta rápida)

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
| `<leader>gf` | Commit referenciando issue |
| `<leader>gi` / `gu` | Init / adotar identidade |
| `<leader>gb` | Configurar bridge com GitHub |

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
- **Git** (`<leader>g`) → `gg` (LazyGit), `gs` (Gitsigns), `gb` (Blame)

> 📘 Lista completa de atalhos em [`KEYMAPS.md`](./KEYMAPS.md)

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
2. Instale as dependências: `Quarto CLI`, `vim-slime`, `gh` (para git‑bug), `nvr` (opcional), `codecompanion.nvim`.
3. Configure o Kitty para remote control (necessário para `<leader>gl`).
4. Inicie o LM Studio com um modelo e ajuste a URL/porta no bloco do CodeCompanion.

---

## 📚 Documentação detalhada

- **Atalhos completos e personalização:** [`KEYMAPS.md`](./KEYMAPS.md)
- **Integração Git‑Bug offline:** [`GITBUG.md`](./GITBUG.md)
- **CodeCompanion + LM Studio:** [`IA.md`](./IA.md)
- **Shadow System do Quarto:** [`QUARTO_SHADOW.md`](./QUARTO_SHADOW.md)

---

## 🔗 Principais referências

- [Neovim](https://github.com/neovim) · [quarto-nvim](https://github.com/quarto-dev/quarto-nvim) · [otter.nvim](https://github.com/jmbuhr/otter.nvim)
- [codecompanion.nvim](https://github.com/olimorris/codecompanion.nvim) · [git‑bug](https://github.com/MichaelMure/git-bug)

---

**Divirta-se estudando e produzindo com velocidade!** 🚀
