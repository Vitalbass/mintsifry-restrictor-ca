#!/bin/sh
set -e

# Подставляем переменные из окружения или используем дефолты, если они пусты
KEY_PATH="/out/${LOCAL_KEY_NAME:-local_restricted_ca.key}"
CRT_PATH="/out/${LOCAL_CRT_NAME:-local_restricted_ca.crt}"
SUB_CRT_PATH="/out/${MINCIFRA_SUB_CA_NAME:-russian_trusted_sub_ca.cer}"

URL_ROOT="${URL_ROOT_CA:-https://gu-st.ru}"
URL_SUB="${URL_SUB_CA:-https://gu-st.ru}"

CSR_PATH="/tmp/local_ca.csr"

# 1. Проверка или генерация локального ключа
if [ -f "$KEY_PATH" ]; then
    echo "🔑 Найден существующий приватный ключ: $KEY_PATH. Используем его..."
else
    echo "🆕 Приватный ключ не найден. Генерация нового ключа: $KEY_PATH..."
    openssl genrsa -out "$KEY_PATH" 4096
fi

echo "2. Загрузка оригинальных сертификатов..."
echo "   Скачиваем корень..."
curl -s -o /tmp/mintsifra_root.crt "$URL_ROOT"
echo "   Скачиваем выпускающий (Sub CA) в: $SUB_CRT_PATH..."
curl -s -o "$SUB_CRT_PATH" "$URL_SUB"

echo "3. Создание запроса на сертификат (CSR)..."
openssl req -new -key "$KEY_PATH" -config /openssl.cnf -out "$CSR_PATH"

echo "4. Переподпись корневого сертификата с расширением Name Constraints..."
openssl x509 -req -in "$CSR_PATH" \
    -signkey "$KEY_PATH" \
    -extfile /openssl.cnf -extensions v3_ca \
    -days 3650 -sha256 \
    -out "$CRT_PATH"

echo "✅ Готово! Процесс успешно завершен."
echo "   - Ваш ограниченный Корень: $CRT_PATH"
echo "   - Выпускающий Sub CA:     $SUB_CRT_PATH"
