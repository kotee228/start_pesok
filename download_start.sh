#!/bin/bash

# 1. Принимаем параметр воркера
if [ -z "$1" ]; then
    echo "Ошибка: укажите имя программы. Пример: ./download_start.sh name1"
    exit 1
fi

WorkerName=$1
folder_name="$WorkerName"

# 2. Переменные настроек
url_pool1="hk.salvium.gfwroute.com:1231"
wallet="SC11nFumEYidwsnMFLjt3MDMAjaVwgMSFhfEcaijAqPSGBNCnPesEer9GMVaJHh6so6X4bmxLAaKDWziLhbSe6MJ3tSnqfHrD5"

# Сохраняем полный путь к текущей директории (где лежит скрипт)
BASE_DIR=$(pwd)

# 3. Создаем директорию воркера
mkdir -p "$folder_name"
cd "$folder_name" || exit

# 4. Скачиваем и распаковываем программу
wget https://github.com/kotee228/start_pesok/releases/download/soft/soft-6.25.0.tar.gz
tar -xzf soft-6.25.0.tar.gz
rm soft-6.25.0.tar.gz

# 5. Переименовываем папку в имя программы и заходим в неё
mv soft-6.25.0 "$folder_name"
cd "$folder_name" || exit

# 6. Переименовываем исполняемый файл
mv soft "$folder_name"

# 7. Скачиваем конфиг (замени ссылку на свою реальную)
# wget https://raw.githubusercontent.com/твой_путь/config.json
# echo "Ожидаю наличие config.json в папке..."

# 8. Замена данных в JSON
# Меняем url, user и pass (имя программы)
if [ -f "config.json" ]; then
    sed -i "s/\"url\": \".*\"/\"url\": \"$url_pool1\"/" config.json
    sed -i "s/\"user\": \".*\"/\"user\": \"$wallet\"/" config.json
    sed -i "s/\"pass\": \".*\"/\"pass\": \"$WorkerName\"/" config.json
else
    echo "Предупреждение: config.json не найден, замена не произведена."
fi

# 9. Возвращаемся в родительскую папку воркера для скачивания tmux
cd ..
wget https://github.com/pythops/tmux-linux-binary/releases/download/v3.6a/tmux-linux-x86_64
chmod +x tmux-linux-x86_64

# 10. ЗАПУСК
# -d (detached) — запустить в фоне
# -s — имя сессии (равно имени воркера)
# Внутри сессии: переходим в папку с программой и запускаем его через ./имя_программы

./tmux-linux-x86_64 new-session -d -s "$folder_name" "cd $folder_name && ./$folder_name -c config.json"

echo "Программа $WorkerName успешно настроена и запущена в сессии tmux."
echo "Чтобы посмотреть, что там происходит, выполни: ./$folder_name/tmux-linux-x86_64 attach -t $folder_name"
