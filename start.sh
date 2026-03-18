#!/bin/bash

# 1. Принимаем имя воркера
if [ -z "$1" ]; then
    echo "Ошибка: укажите имя программы. Пример: ./start.sh name1"
    exit 1
fi

WorkerName=$1
folder_name="$WorkerName"

# 2. Проверяем, существует ли директория воркера
if [ ! -d "$folder_name" ]; then
    echo "Ошибка: Директория $folder_name не найдена. Сначала запусти download_start.sh"
    exit 1
fi

# 3. Переходим в общую папку воркера (где лежит tmux)
cd "$folder_name" || exit

# 4. Проверяем наличие tmux и запускаем сессию
if [ -f "./tmux-linux-x86_64" ]; then
    # Убиваем старую сессию с таким же именем, если она вдруг висит (чтобы не плодить ошибки)
    ./tmux-linux-x86_64 kill-session -t "$folder_name" 2>/dev/null

    # Запуск новой сессии в фоне (-d)
    # Внутри сессии: переходим в подпапку воркера и стартуем бинарник с конфигом
    ./tmux-linux-x86_64 new-session -d -s "$folder_name" "cd $folder_name && ./$folder_name -c config.json"
    
    echo "Программа $WorkerName запущен в сессии tmux."
    echo "Для просмотра введи: cd $folder_name && ./tmux-linux-x86_64 attach -t $folder_name"
else
    echo "Ошибка: Файл tmux-linux-x86_64 не найден в $folder_name"
    exit 1
fi
