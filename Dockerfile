FROM alpine:latest

RUN apk add --no-cache openssl curl

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME /out

ENTRYPOINT ["/entrypoint.sh"]
