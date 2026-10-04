#!/bin/sh
set -e

# Пути к конфигурационным файлам
CNF_MAIN="/config/openssl.cnf"
CNF_CROSS="/config/cross.cnf"

# Проверка наличия внешних конфигурационных файлов
if [ ! -f "$CNF_MAIN" ] || [ ! -f "$CNF_CROSS" ]; then
    echo "Ошибка: Внешние файлы конфигурации не найдены в папке /config внутри контейнера!"
    echo "Убедитесь, что вы передали их при запуске: -v \$(pwd)/openssl.cnf:/config/openssl.cnf -v \$(pwd)/cross.cnf:/config/cross.cnf"
    exit 1
fi

# Пути к результирующим файлам внутри контейнера
OUT_KEY="/out/${RESTICTOR_LOCAL_KEY_NAME}"
OUT_CRT="/out/${RESTICTOR_LOCAL_CRT_NAME}"
OUT_ROOT_CRT="/out/${RESTICTOR_LOCAL_ROOT_CRT_NAME}"

# Временная рабочая директория
TMP_DIR="/tmp/cert_build"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

echo "=== 1. Скачивание корневого сертификата Минцифры ==="
curl -sSL -o "$MINCIFRY_ROOT_CA_NAME" "$URL_ROOT_CA"

echo "=== 2. Извлечение публичного ключа Минцифры ==="
openssl x509 -in "$MINCIFRY_ROOT_CA_NAME" -pubkey -noout > digital-gov.pub

echo "=== 3. Проверка / Генерация приватного ключа ==="
if [ -f "$OUT_KEY" ]; then
    echo "Приватный ключ уже существует: $RESTICTOR_LOCAL_KEY_NAME. Пропускаем генерацию."
    cp "$OUT_KEY" ./restrictor-ca.key
else
    echo "Генерация нового приватного ключа..."
    openssl genrsa -out ./restrictor-ca.key 4096
    cp ./restrictor-ca.key "$OUT_KEY"
fi

echo "=== 4. Создание кросс-сертификата ==="
openssl req -x509 -days 3650 \
    -config "$CNF_MAIN" \
    -extensions v3_ca \
    -key ./restrictor-ca.key \
    -out ./restrictor-ca.crt

echo "=== 5. Создание временного запроса (CSR) ==="
openssl req -new -newkey rsa:4096 -nodes \
    -keyout temp.key \
    -out dummy.csr \
    -subj "/CN=Temporary Dummy CSR"

echo "=== 6. Парсинг Subject из оригинального сертификата ==="
SUBJ_RAW=$(openssl x509 -in "$MINCIFRY_ROOT_CA_NAME" -noout -subject)
SUBJ_FORMATTED=$(echo "$SUBJ_RAW" | sed -e 's/^subject=//' -e 's/, /\//g' -e 's/^/\//')

echo "Оригинальный Subject: $SUBJ_RAW"
echo "Сформатированный Subject: $SUBJ_FORMATTED"

echo "=== 7. Создание кросс-корневого сертификата ==="
openssl x509 -req -in dummy.csr \
    -CA ./restrictor-ca.crt \
    -CAkey ./restrictor-ca.key \
    -CAcreateserial \
    -days 3650 -sha256 \
    -force_pubkey digital-gov.pub \
    -out ./restrictor-root-ca.crt \
    -extfile "$CNF_CROSS" \
    -extensions cross_ca_ext \
    -subj "$SUBJ_FORMATTED"

echo "=== 8. Экспорт результатов в папку назначения (/out) ==="
cp ./restrictor-ca.crt "$OUT_CRT"
cp ./restrictor-root-ca.crt "$OUT_ROOT_CRT"

echo "=== Готово! Сертификаты успешно созданы ==="
ls -lh /out
