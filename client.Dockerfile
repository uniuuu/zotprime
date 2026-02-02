# syntax=docker/dockerfile:1
ARG ZOTPRIME_VERSION=2
FROM node:22-alpine AS stage-1

# Install custom CA certificate if provided
RUN --mount=type=secret,id=custom_ca,target=/tmp/custom_ca.crt \
    if [ -f /tmp/custom_ca.crt ]; then \
        mkdir -p /usr/local/share/ca-certificates/ /etc/ssl/certs && \
        cp /tmp/custom_ca.crt /usr/local/share/ca-certificates/custom_ca.crt && \
        cat /usr/local/share/ca-certificates/custom_ca.crt >> /etc/ssl/certs/ca-certificates.crt && \
        npm config set cafile /etc/ssl/certs/ca-certificates.crt && \
        echo "Custom CA certificate installed"; \
    else \
        echo "No custom CA certificate provided, skipping"; \
    fi

RUN set -eux; \ 
    apk update && apk upgrade && \
    apk add --update --no-cache \
    git \
    git-lfs \
    perl \
    && rm -rf /var/cache/apk/*
WORKDIR /usr/src/app
COPY .git .git
COPY client client

WORKDIR /usr/src/app/client/zotero-client
# RUN git checkout main
# RUN rm -rf *
# RUN git checkout -- .
RUN git submodule update --init --recursive
RUN git lfs pull
RUN git submodule foreach git lfs pull

WORKDIR /usr/src/app/client/
#ARG CONFIG=config.sh
ARG HOST_DS=http://localhost:8080/
ARG HOST_ST=ws://localhost:8081/
RUN set -eux; \
        sed -i "s#https://api.zotero.org/#$HOST_DS#g" zotero-client/resource/config.mjs; \
        sed -i "s#wss://stream.zotero.org/#$HOST_ST#g" zotero-client/resource/config.mjs; \
        perl -i -pe "s#https://www\.zotero\.org/(?!start)#$HOST_DS#g" zotero-client/resource/config.mjs; \
        sed -i "s#https://zoteroproxycheck.s3.amazonaws.com/test##g" zotero-client/resource/config.mjs
#    ./$CONFIG

FROM node:22-alpine AS stage-2

RUN set -eux; \ 
    apk update && apk upgrade && \
    apk add --update --no-cache \
    file \
    git \
    git-lfs \
    grep \
    bash \
    binutils \
    coreutils \
    curl \
    ncurses \
    openssl \
    perl \
    python3 \
    rsync \
#    util-linux \
    tar \
    xz \
    zip \
    7zip \
    && rm -rf /var/cache/apk/*
WORKDIR /usr/src/app

COPY --from=stage-1 /usr/src/app .

RUN ls -lha

WORKDIR /usr/src/app/client/zotero-client

RUN ls -lha

#RUN set -eux; \
#     npx browserslist@latest --update-db --legacy-peer-deps

ARG MLW=l

RUN set -eux; \
    npm config set fetch-retry-mintimeout 20000; \
    npm config set fetch-retry-maxtimeout 120000; \
    npm config set fetch-retries 5; \
    npm i

RUN set -eux; \
     npm run build

RUN set -eux; \
     app/scripts/dir_build -p $MLW

FROM scratch AS export-stage
COPY --from=stage-2 /usr/src/app/client/zotero-client/app/staging .
