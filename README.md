# 🚀 Obsidian + Neovim: Integração Híbrida (Dotfile para o pseudo init)

Esta configuração permite que o Neovim e o Obsidian funcionem como uma única ferramenta. O Neovim atua como o motor de navegação e edição avançada, enquanto o Obsidian cuida da interface gráfica e renderização.

Demo:


## 📂 Onde colocar cada arquivo

Para que a integração funcione, os arquivos/pasta deste repositório devem ser distribuídos nos seguintes endereços do seu sistema:

| Arquivo | Destino | Função |
| :--- | :--- | :--- |
| `start-nvim-obsidian.sh` | Qualquer | Script que limpa a porta 2006 e inicia o servidor Neovim. |
| `init.lua` (Pseudo-Config) | `~/.config/nvim-obsidian/` | Perfil isolado que ativa a ponte e herda sua config Master. |
| `*.css` | `[Vault]/.obsidian/snippets/` | Snippets CSS para a interface responsiva (gaveta). |
| `edit-in-neovim-modificado` | `[Vault]/.obsidian/plugins/` | | `*.css` | `[Vault]/.obsidian/snippets/` | Snippets CSS para a interface responsiva (gaveta). | Plugin que sicroniza o buffer do obsidian para o neovim. |

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

## ⚠️ Notas Importantes para Arch Linux
- **Permissões:** Certifique-se de que o script de inicialização é executável:
  ```bash
  chmod +x ~/start-nvim-obsidian.sh
  ```
- **Dependências:** O script utiliza `fuser` e `lsof` para gerenciar a porta 2006. Instale-os via pacman:
  ```bash
  sudo pacman -S psmisc lsof
  ```
- **Nerd Fonts:** A pseudo-configuração desativa Nerd Fonts no terminal integrado para manter o visual limpo em janelas pequenas, enquanto sua configuração Master (`nvim`) continuará com ícones normais quando aberta fora do Obsidian.
