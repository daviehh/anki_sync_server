FROM rust:alpine AS builder

# ARG UID=1030
# ARG GID=100

RUN apk update && apk add --no-cache build-base protobuf curl jq && rm -rf /var/cache/apk/*
RUN cargo install --git https://github.com/ankitects/anki.git \
    --tag "$(curl -s 'https://api.github.com/repos/ankitects/anki/tags' | jq -r '.[0].name')" \
    --root /anki-server  \
    anki-sync-server

FROM alpine:latest

RUN (addgroup -g 100 ankigrp || true) && \
	adduser -D -h /home/anki anki \
    --uid 1030 --ingroup "$(getent group 100 | cut -d: -f1)"

COPY --from=builder /anki-server/bin/anki-sync-server /usr/local/bin/anki-sync-server

RUN apk update && apk add --no-cache bash && rm -rf /var/cache/apk/*

USER anki

ENV SYNC_PORT=${SYNC_PORT:-"8080"}

EXPOSE ${SYNC_PORT}

CMD ["anki-sync-server"]
