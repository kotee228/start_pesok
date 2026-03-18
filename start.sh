#!/bin/bash

if [ -z "$1" ]; then
    echo "Ошибка: укажите имя программы. Пример: ./start.sh name1"
    exit 1
fi

WorkerName=$1
folder_name="$WorkerName"

# --- НАСТРОЙКИ TELEGRAM (должны совпадать) ---
TG_TOKEN="1604215410:AAFQ-Xui9lzGIkMrbqxCUBVM02hXDvQN00Y"
TG_CHAT_ID="415568022"
INTERVAL=60
# --------------------------

if [ ! -d "$folder_name" ]; then
    echo "Ошибка: Директория $folder_name не найдена."
    exit 1
fi

cd "$folder_name" || exit

if [ -f "./tmux-linux-x86_64" ]; then
    # Убиваем обе сессии перед перезапуском
    ./tmux-linux-x86_64 kill-session -t "$folder_name" 2>/dev/null
    ./tmux-linux-x86_64 kill-session -t "TG$folder_name" 2>/dev/null

    # Запуск программы
    ./tmux-linux-x86_64 new-session -d -s "$folder_name" "cd $folder_name && ./$folder_name -c config.json"
    
    # Запуск мониторинга (скрипт tg_monitor.sh уже создан при установке)
    ./tmux-linux-x86_64 new-session -d -s "TG$folder_name" "./tg_monitor.sh"
    
    echo "Программа $WorkerName и TG мониторинг перезапущены."
else
    echo "Ошибка: tmux не найден."
    exit 1
fi
