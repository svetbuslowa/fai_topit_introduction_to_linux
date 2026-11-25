#!/bin/bash
# Проверка прав root
if [ "$EUID" -ne 0 ]; then
    echo "ОШИБКА: скрипт должен запускаться от имени root (sudo)"
    exit 1
fi

# Проверка числа параметров
if [ "$#" -ne 2 ]; then
    echo "Использование: $0 <количество> <начальный_номер>"
    echo "Пример: $0 5 1"
    exit 1
fi

count=$1
start=$2

for (( i=0; i<count; i++ )); do
    num=$((start + i))
    user="u${num}"
    pass="DerParol${num}"

    # Проверка существования пользователя
    if id "$user" &>/dev/null; then
        echo "Пользователь $user уже существует — пропускаю"
    else
        useradd -m "$user"
        echo "$user:$pass" | chpasswd
        echo "Создан пользователь $user"
    fi
done