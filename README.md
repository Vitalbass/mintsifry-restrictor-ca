# mintsifry-restrictor-ca
Docker-контейнер для переподписывания сертификатов Минцифры с ограничением области действия по конкретным DNS-записям.
Docker image for re-signing Mintsifry (Russian Ministry of Digital Development) CA certificates with DNS-scoped constraints.


# 1. Собираем образ 
docker build -t mintsifry-restrictor-ca .

# 2. В openssl.cnf задаем перечень dns-имен 
В секции permitted_domains редактируем\добавляем permitted;DNS.ХХ, для которых разрешено использовать сертификат

# 3. Запускаем генерацию
# Монитруем текущую папку для сохранения ключа/сертификата И  файл конфигурации
docker run --rm \
  --env-file .env \
  -v "$(pwd):/out" \
  -v "$(pwd)/openssl.cnf:/openssl.cnf:ro" \
  mintsifry-restrictor-ca
