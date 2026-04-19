# 🐙 Github CLI + Lazygit + Gitsins + Git‑bug

O **Lazygit** facilita o rastreio dos arquivos. Já O **git‑bug** é um rastreador de bugs/questões que armazena tudo no próprio repositório Git. Você pode gerenciar ambos **completamente offline** e sincronizar com o GitHub quando tiver internet. Instale-os, junto ao Github-CLI (gh) devidamente configurado com uma chave do seu perfil do seu perfil github (e feito uma única vez por computador). Recomendo adicionar ao seu `~/.bashrc` esta automatização de credências básicas, abaixo:

```
export GIT_BUG_USER_NAME="$(git config user.name)"
export GIT_BUG_USER_EMAIL="$(git config user.email)"
```

## 🚀 Primeiros passos (único para cada repositório)

1. **Inicialize o git‑bug** no repositório atual:
   - `<leader>gi` → `git init`

2. **Adote uma identidade** (necessário para assinar issues):
   - `<leader>gu` → `git bug user adopt`

3. (Online, uma vez) **Configure a bridge com o GitHub**:
   - `<leader>gz` → abre terminal interativo para configurar a ponte manualmente, caso ainda não tenha uma. (o gp deve conseguir configurar automaticamente com o Github-CLI e as credênciais básicas do kitty configuradas)

## 📋 Atalhos principais

| Atalho      | Ação                                                                 |
|-------------|-----------------------------------------------------------------------|
| `<leader>gg`| **Lazygit**: abre janela flutuante do programa                 |
| `<leader>ga`| **Nova issue**: abre janela flutuante para título e descrição.         |
| `<leader>gl`| **Interface TUI**: abre o terminal interativo do git‑bug (via Kitty float). |
| `<leader>gp`| **Push/Pull**: envia e recebe atualizações de issues do GitHub.                  |
| `<leader>gk`| **Gerenciar keyrings**: apaga todas as keyrings ou uma específica (útil para corrigir autenticação). |

## 🔄 Fluxo de issues offline → online

1. **Offline**:
   - Crie issues com `<leader>ga` ou `<leader>gl`.
   - Adicione comentários, altere status, etc com `<leader>gl` (tudo fica armazenado no `.git`).
2. **Online**:
   - Execute `<leader>gp` para enviar tudo ao GitHub.
   - As issues aparecerão na interface web normalmente.

Obs.: O pull e push do `<leader>gl` não interage com os issues do github, ele serve para modificar os arquivos locais/remoto dos repositórios. Use `<leader>gp` para sincronizar com os issues do github!!

## 🖥️ Configuração do Kitty (para `<leader>gl`)

Adicione ao `~/.config/kitty/kitty.conf`:

```
allow_remote_control yes
listen_on unix:/tmp/kitty
```

## 🛠️ Comandos manuais úteis

| Comando                         | Descrição                               |
|---------------------------------|-----------------------------------------|
| `git bug bug new -t "Título"`   | Criar issue via linha de comando        |
| `git bug termui`                | Abrir TUI manualmente                   |
| `git bug bridge new`            | Configurar bridge interativamente       |
| `git bug pull` / `push`         | Sincronizar                             |

## 📌 Observações

- O git‑bug funciona em **qualquer repositório Git**, independentemente de estar conectado a um remote.
- As issues são armazenadas como objetos Git na branch `bugs` (oculta).
- Para colaboração, todos os envolvidos devem ter o git‑bug instalado e a bridge configurada.

**Documentação oficial:** [github.com/MichaelMure/git-bug](https://github.com/MichaelMure/git-bug)
