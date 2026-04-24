#!/bin/bash

# 1. Força a finalização imediata (SIGKILL -9) de qualquer processo na porta 2006
fuser -k -9 2006/tcp 2>/dev/null

# 2. Aguarda um curto período para o kernel do Linux liberar o socket
sleep 2.5

# 3. Verifica se a porta ainda está ocupada (caso o fuser falhe)
# Se estiver, tenta matar pelo PID via lsof (mais preciso)
if lsof -Pi :2006 -sTCP:LISTEN -t >/dev/null ; then
    kill -9 $(lsof -t -i:2006)
    sleep 0.3
fi

# 4. Inicia o Neovim
export TERM=xterm-256color
export COLORTERM=truecolor
export NVIM_APPNAME=nvim-obsidian
exec nvim --listen 127.0.0.1:2006
