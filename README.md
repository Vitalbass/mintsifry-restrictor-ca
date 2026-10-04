# mintsifry-restrictor-ca
Docker-контейнер для переподписывания сертификатов Минцифры с ограничением области действия по конкретным DNS-записям.
Docker image for re-signing Mintsifry (Russian Ministry of Digital Development) CA certificates with DNS-scoped constraints.


# 1. Копирует удаленный репозиторий 
```
git clone https://github.com/Vitalbass/mintsifry-restrictor-ca.git
```

# 2. Собираем образ
```
docker build -t mintsifry-restrictor-ca .
```

# 2. В openssl.cnf задаем перечень dns-имен 
В секции permitted_domains редактируем\добавляем permitted;DNS.ХХ, для которых разрешено использовать сертификат

# 3. Запускаем генерацию
# Монитруем текущую папку для сохранения ключа/сертификата И  файл конфигурации
```
docker run --rm \
--env-file .env \
-v "/$(pwd)/out:/out" \
-v "/$(pwd)/openssl.cnf:/config/openssl.cnf:ro" \
-v "/$(pwd)/cross.cnf:/config/cross.cnf:ro" \
mintsifry-restrictor-ca
```

# 4. Устанавливаем сертификат в ОС\браузер и т.д.
 - restrictor-ca.crt (ставим доверять для идентификации веб-сайтов)
 - restrictor-root-ca.crt (просто добавить)


# 5. Проверка сертификата:
```
openssl storeutl -text -noout -certs restrictor-root-ca.crt
openssl storeutl -text -noout -certs restrictor-ca.crt | grep -A 10 "Name Constraints"
```
