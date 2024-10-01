ARG ZOTPRIME_VERSION=2
FROM node:20-alpine AS stage-1
RUN set -eux; \ 
    apk update && apk upgrade && \
    apk add --update --no-cache \
    git \
    git-lfs \
    && rm -rf /var/cache/apk/*
WORKDIR /usr/src/app
COPY .git .git
COPY client client

WORKDIR /usr/src/app/client/zotero-client
#RUN git checkout tags/7.0.6 -b v7.0.6
#RUN git checkout 7.0.6-hotfix
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
        sed -i "s#https://api.zotero.org/#$HOST_DS#g" zotero-client/resource/config.js; \
        sed -i "s#wss://stream.zotero.org/#$HOST_ST#g" zotero-client/resource/config.js; \
        sed -i "s#https://www.zotero.org/#$HOST_DS#g" zotero-client/resource/config.js; \
        sed -i "s#https://zoteroproxycheck.s3.amazonaws.com/test##g" zotero-client/resource/config.js
#    ./$CONFIG

FROM node:20-alpine AS stage-2

RUN set -eux; \ 
    apk update && apk upgrade && \
    apk add --update --no-cache \
    file \
    git \
    git-lfs \
    grep \
    bash \
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
    npm i

RUN set -eux; \
     npm run build

RUN set -eux; \
     app/scripts/dir_build -p $MLW

FROM scratch AS export-stage
COPY --from=stage-2 /usr/src/app/client/zotero-client/app/staging .