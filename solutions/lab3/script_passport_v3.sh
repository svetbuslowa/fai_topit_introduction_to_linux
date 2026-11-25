#!/bin/bash

REPORT_FILE="${1:-PASSPORT/inventory.txt}"
LOG_FILE="${2:-PASSPORT/script.log}"

usage() { echo "Использование: $0 [отчет] [лог]"; exit 0; }
die() { echo "ОШИБКА: $1" >&2; exit 1; }

check_privileges() {
    if [ "$EUID" -ne 0 ] && ! groups | grep -q '\bsudo\b'; then
        die "Недостаточно прав. Запустите: sudo $0"
    fi
}

check_tool() {
    command -v "$1" &>/dev/null || echo "ВНИМАНИЕ: утилита '$1' не найдена" >&2
}

log_run() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Запуск скрипта инвентаризации (формат v3)" >> "$LOG_FILE"
}

cleanup() { rm -f /tmp/lab3_passport_*.tmp 2>/dev/null; }
trap cleanup EXIT

[ "$1" = "-h" ] && usage

check_privileges
check_tool sshd
check_tool getent
log_run

mkdir -p "$(dirname "$REPORT_FILE")"
echo "=== Аудит безопасности (v3) ===" > "$REPORT_FILE"
echo "Дата: $(date)" >> "$REPORT_FILE"
echo "Запущен от: $(whoami)" >> "$REPORT_FILE"

echo -e "\n=== Пользователи (root и UID>=1000) ===" >> "$REPORT_FILE"
getent passwd | awk -F: '$3==0 || $3>=1000 {print $1}' | while read u; do
    echo "- $u" >> "$REPORT_FILE"
    id "$u" 2>/dev/null | sed 's/^/  /' >> "$REPORT_FILE"
    LC_ALL=C chage -l "$u" 2>/dev/null | grep -i "password change" | sed 's/^/  /' >> "$REPORT_FILE"
    if command -v lastlog2 &>/dev/null; then
        lastlog2 -u "$u" 2>/dev/null | tail -n +2 | sed 's/^/  Последний вход: /' >> "$REPORT_FILE"
    else
        echo "  Последний вход: lastlog2 не установлен" >> "$REPORT_FILE"
    fi
done

echo -e "\n=== Параметры sshd (эффективные) ===" >> "$REPORT_FILE"
sshd -T 2>/dev/null | grep -E '^(permitrootlogin|port|logingracetime|maxauthtries|passwordauthentication|pubkeyauthentication) ' >> "$REPORT_FILE"

echo -e "\n=== Топ-5 процессов по памяти ===" >> "$REPORT_FILE"
ps -eo pid,ppid,user,%mem,cmd --sort=-%mem | head -n 6 >> "$REPORT_FILE"

echo -e "\n=== Подозрительные учётные записи ===" >> "$REPORT_FILE"
echo "UID 0 кроме root:" >> "$REPORT_FILE"
awk -F: '$3==0 && $1!="root" {print "  " $1}' /etc/passwd >> "$REPORT_FILE"
echo "Пустой пароль:" >> "$REPORT_FILE"
awk -F: '$2=="" {print "  " $1}' /etc/shadow 2>/dev/null >> "$REPORT_FILE" || echo "  (нет доступа к shadow)" >> "$REPORT_FILE"

echo -e "\n=== Файлы с SUID ===" >> "$REPORT_FILE"
find /usr/bin /usr/sbin -perm -4000 2>/dev/null | head -n 15 >> "$REPORT_FILE"

echo "Готово: $REPORT_FILE"
