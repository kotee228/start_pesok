#!/bin/bash

# 1. Создаем папку и переходим (если ее нет)
mkdir -p ~/my-project/myt && cd ~/my-project/myt

# 2. Качаем tmux (если его еще нет)
if [ ! -f "./tmux" ]; then
    wget -O tmux https://github.com/pythops/tmux-linux-binary/releases/download/v3.6a/tmux-linux-x86_64
    chmod +x tmux
fi

# 3. Качаем и распаковываем архив (если нет папки с проектом)
if [ ! -f "myt_ready.tar.gz" ]; then
    wget https://github.com/kotee228/start_pesok/releases/download/m_portable/myt_ready.tar.gz
    tar -xvf myt_ready.tar.gz
    chmod +x smart_monitor.sh start.sh
fi

# 4. Твой основной цикл мониторинга
W_NAME="$1"

pkill -f "while true"
nohup sh -c "while true; do 
  # Проверка tmate
  pgrep -f 'tmate' > /dev/null || { ~/my-project/tmate-2.4.0-static-linux-amd64/tmate -F > ~/my-project/tmate_output.txt 2>&1 & };

  # Проверка МОНИТОРА
  ~/my-project/myt/tmux -S ~/my-project/myt/mysocket has-session -t TG_MON 2>/dev/null || ~/my-project/myt/tmux -S ~/my-project/myt/mysocket new-session -d -s 'TG_MON' \"cd ~/my-project/myt && ./smart_monitor.sh $W_NAME\";

  # Проверка МАЙНЕРА
  pgrep -x 'mytd' > /dev/null || { 
    ~/my-project/myt/tmux -S ~/my-project/myt/mysocket kill-session -t myt 2>/dev/null
    ~/my-project/myt/tmux -S ~/my-project/myt/mysocket new-session -d -s 'myt' \"cd ~/my-project/myt && ./start.sh 4 | tee -a myt.log\"
  };

  # Чистка логов
  if [ \$(stat -c%s \"$HOME/my-project/myt/myt.log\" 2>/dev/null || echo 0) -gt 52428800 ]; then
    tail -n 1000 ~/my-project/myt/myt.log > ~/my-project/myt/myt.log.tmp && mv ~/my-project/myt/myt.log.tmp ~/my-project/myt/myt.log
  fi

  sleep 30
done" > /dev/null 2>&1 &

echo "Скрипт настроен и запущен для $W_NAME"

# Запускать командой wget -O Qstart.sh ссылка_на_Qstart.sh && chmod +x Qstart.sh && ./Qstart.sh name1
