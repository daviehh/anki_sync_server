FROM rust:1-slim-bookworm AS builder

RUN apt-get update -y && apt-get install -y build-essential protobuf-compiler curl jq && \
	echo -n "$(curl -s 'https://api.github.com/repos/ankitects/anki/tags' | jq -r '.[0].name')" > /etc/ankitag && \
	echo "> compile: anki tag [$(cat /etc/ankitag)]" && \
	cargo install --git https://github.com/ankitects/anki.git \
	--tag $(cat /etc/ankitag) \
	--root /anki-server \
	anki-sync-server


FROM debian:bookworm-slim

ARG UID=1030
ARG GID=100

RUN (addgroup --gid $GID ankigrp || true) && \
	adduser --home /home/anki \
	--uid $UID --gid $GID \
	anki

COPY --from=builder /anki-server/bin/anki-sync-server /usr/local/bin/anki-sync-server

RUN apt-get update -y && apt-get install -y bash && apt-get clean -y

USER anki

ENV SYNC_PORT=${SYNC_PORT:-"8080"}

EXPOSE ${SYNC_PORT}

CMD ["anki-sync-server"]
