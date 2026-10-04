FROM alpine:latest

RUN apk add --no-cache openssl curl bash

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME /in
VOLUME /out


ENTRYPOINT ["/entrypoint.sh"]
