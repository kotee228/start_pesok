#!/bin/bash

# --- НАСТРОЙКИ ---
TOKEN_1="1604215410:AAFQ-Xui9lzGIkMrbqxCUBVM02hXDvQN00Y"
TOKEN_2="6134438182:AAE_27te6xHjTCixnWOjCcMw43OA9Z3JuEs"
CHAT_ID="415568022"
W_NAME="$1"
LOG_FILE="myt.log"
TMATE_LOG="../tmate_output.txt"
TMATE_PATH="../tmate-2.4.0-static-linux-amd64/tmate"

SMILES=("🌸" "🚀" "💎" "🔥" "⚡" "🍀" "🌟" "👾" "🍕" "👑" "🎯")

# Исправленная функция отправки (теперь с поддержкой HTML)
send_tg() {
    curl -s -X POST "https://api.telegram.org/bot$1/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d parse_mode="HTML" \
        -d text="$2" > /dev/null
}

get_sys_status() {
    local date_now=$(date '+%d.%m.%Y %H:%M')
    local cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}' | cut -d. -f1)
    local la=$(awk '{print $1, $2, $3}' /proc/loadavg)
    local cores=$(nproc)
    local ip=$(curl -s ifconfig.me)
    
    # Четкий парсинг ссылки без лишних префиксов
    local web_url=$(grep -a "web session:" "$TMATE_LOG" | tail -n 1 | sed 's/.*web session: //')
    local ssh_url=$(grep -a "ssh session:" "$TMATE_LOG" | tail -n 1 | sed 's/.*ssh session: //')
    
    # Формируем отчет с HTML-тегами <code> для копирования кликом
    local report="<b>📊 /_$W_NAME | 🕒 $date_now</b>%0A"
    report+="🌐 IP: <code>$ip</code>%0A"
    report+="💻 $cores CPU: $cpu%%0A📈 LA: $la%0A%0A"
    report+="🌐 <b>Веб-ссылка:</b>%0A$web_url%0A%0A"
    report+="🔑 <b>SSH команда (кликни для копии):</b>%0A<code>$ssh_url</code>%0A%0A"
    report+="🔄 Обновить связь: /_relink_$W_NAME"
    
    echo "$report"
}

# --- ПРИВЕТСТВИЕ ---
send_tg "$TOKEN_2" "🚀 <b>СИСТЕМА ЗАПУЩЕНА!</b> 🚀%0AВоркер: /_$W_NAME%0A$(get_sys_status)"

# 1. ПРОВЕРКА ЖИВУЧЕСТИ
(
while true; do
    sleep 600
    URL=$(grep -a "web session:" "$TMATE_LOG" | tail -n 1 | sed 's/.*web session: //')
    if [ ! -z "$URL" ]; then
        CHECK=$(curl -o /dev/null -s -w "%{http_code}" --max-time 5 "$URL")
        if [ "$CHECK" == "503" ] || [ "$CHECK" == "000" ]; then
            send_tg "$TOKEN_2" "⚠️ /_relink_$W_NAME Попробуй, tmate.io тупит (Код $CHECK)."
        fi
    fi
done
) &

# 2. ОБРАБОТЧИК КОМАНД
(
OFFSET=-1
while true; do
    UPDATES=$(curl -s --max-time 10 "https://api.telegram.org/bot$TOKEN_2/getUpdates?offset=$OFFSET&limit=1")
    if echo "$UPDATES" | grep -q "/_$W_NAME" || echo "$UPDATES" | grep -q "/status $W_NAME"; then
        MSG=$(get_sys_status)
        send_tg "$TOKEN_2" "$MSG"
    elif echo "$UPDATES" | grep -q "/_relink_$W_NAME"; then
        send_tg "$TOKEN_2" "🔄 Перезапускаю tmate для /_$W_NAME... Жди 25 сек."
        pkill -f tmate
        sleep 2
        $TMATE_PATH -F > "$TMATE_LOG" 2>&1 &
        sleep 23
        MSG=$(get_sys_status)
        send_tg "$TOKEN_2" "✅ <b>Ссылка обновлена:</b>%0A$MSG"
    fi
    LAST_ID=$(echo "$UPDATES" | grep -oP '"update_id":\K[0-9]+' | tail -n 1)
    [ ! -z "$LAST_ID" ] && OFFSET=$((LAST_ID + 1))
    sleep 2
done
) &

# 3. МОНИТОРИНГ БЛОКОВ
tail -F "$LOG_FILE" | grep --line-buffered "Found block" | while read -r line; do
    HEIGHT=$(echo "$line" | grep -o "at height [0-9]*")
    send_tg "$TOKEN_2" "❤️💰❤️ <b>БЛОК НАЙДЕН!</b> /_$W_NAME%0A$HEIGHT"
done &

# 4. ПУЛЬС (Бот 1 - без HTML, чтобы не нагружать чат)
while true; do
    DATE_P=$(date '+%d.%m.%Y %H:%M')
    CPU_P=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}' | cut -d. -f1)
    LA_P=$(awk '{print $1, $2, $3}' /proc/loadavg)
    CORES_P=$(nproc)
    SMILE_P=${SMILES[$RANDOM % ${#SMILES[@]}]}
    TEXT="$SMILE_P /_$W_NAME | $CORES_P CPU: $CPU_P% | LA: $LA_P | $DATE_P"
    # Для пульса используем обычную отправку без тегов
    curl -s -X POST "https://api.telegram.org/bot$TOKEN_1/sendMessage" -d chat_id="$CHAT_ID" -d text="$TEXT" > /dev/null
    sleep 60
done
