# 🤖 IA Local – CodeCompanion + LM Studio

Assistente de código **offline** integrado ao Neovim. Utiliza modelos de linguagem executados localmente via **LM Studio**, garantindo privacidade e baixa latência.

## ⚙️ Configuração

1. **Instale o LM Studio** e carregue um modelo (ex.: `google/gemma-4-e2b`).
2. Inicie o servidor local (padrão: `http://localhost:1234`).
3. O plugin `codecompanion.nvim` já está configurado para usar esse endpoint.

## ⌨️ Atalhos

| Atalho      | Modo         | Ação                                                                 |
|-------------|--------------|-----------------------------------------------------------------------|
| `<leader>ca`| Normal/Visual| Abrir menu de ações (explicar código, corrigir bugs, etc.)             |
| `<leader>cc`| Normal/Visual| Alternar janela de **Chat** – para discussões teóricas ou lógica.      |
| `<leader>ci`| Normal/Visual| **Prompt Inline**: gerar ou modificar o código sob o cursor.           |
| `ga`        | Visual       | Adicionar a seleção atual à conversa do chat.                          |

## 🧪 Exemplos de uso

- **Explicar uma função**: selecione o código, `<leader>ca` → "Explain".
- **Gerar teste unitário**: posicione o cursor, `<leader>ci` → "write unit tests for this function".
- **Debater conceitos**: `<leader>cc` → "Qual a diferença entre `map` e `apply` em Julia?".

## 🔌 Adaptador LM Studio

A configuração do adaptador está no bloco do `codecompanion.nvim`:

```lua
adapters = {
  lmstudio = {
    name = 'lmstudio',
    url = 'http://localhost:1234',
    api_key = 'lm-studio',
    model = 'google/gemma-4-e2b',
    adapter = 'openai_compatible',
  },
}
```

Ajuste a `url` e o `model` conforme seu ambiente.

## 📦 Dependências

- [codecompanion.nvim](https://github.com/olimorris/codecompanion.nvim)
- [LM Studio](https://lmstudio.ai/) (ou outro servidor compatível com OpenAI API)

> 💡 O LM Studio gerencia o download e a execução dos modelos de forma simples.

---

**Aproveite o poder da IA sem sair do Neovim e sem depender de nuvem!**
