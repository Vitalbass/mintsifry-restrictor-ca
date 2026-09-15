# mintsifry-restrictor-ca
Docker-контейнер для переподписывания сертификатов Минцифры с ограничением области действия по конкретным DNS-записям.


# 1. Собираем образ 
docker build -t mintsifra-restrictor .

# 2. Запускаем генерацию
# Монитруем текущую папку для сохранения ключа/сертификата И  файл конфигурации
docker run --rm \
  -v "$(pwd):/out" \
  -v "$(pwd)/openssl.cnf:/openssl.cnf:ro" \
  mintsifry-restrictor-ca
