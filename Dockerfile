FROM rust:alpine AS builder

RUN apk update && apk add --no-cache build-base protobuf curl jq && \
	echo -n "$(curl -s 'https://api.github.com/repos/ankitects/anki/tags' | jq -r '.[0].name')" > /etc/ankitag && \
	echo "> compile: anki tag [$(cat /etc/ankitag)]" && \
	cargo install --git https://github.com/ankitects/anki.git \
	--tag $(cat /etc/ankitag) \
	--root /anki-server \
	anki-sync-server


FROM alpine:latest

ARG UID=1030
ARG GID=100

RUN (addgroup -g $GID ankigrp || true) && \
	adduser -D -h /home/anki anki \
	--uid $UID --ingroup "$(getent group $GID | cut -d: -f1)"

COPY --from=builder /anki-server/bin/anki-sync-server /usr/local/bin/anki-sync-server

RUN apk update && apk add --no-cache bash && rm -rf /var/cache/apk/*

USER anki

ENV SYNC_PORT=${SYNC_PORT:-"8080"}

EXPOSE ${SYNC_PORT}

CMD ["anki-sync-server"]
