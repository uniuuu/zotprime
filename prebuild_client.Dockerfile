FROM alpine:3 AS intermediate
ARG ZOTPRIME_VERSION=2

RUN set -eux; \ 
    apk update && apk upgrade && \
    apk add --update --no-cache \
    curl \
    zip \
    7zip \
    perl \
    && rm -rf /var/cache/apk/*
WORKDIR /usr/app
RUN mkdir /usr/app/build 
RUN curl -sSO https://download.zotero.org/client/release/8.0/Zotero-8.0_linux-x86_64.tar.xz
RUN tar -xvf Zotero-8.0_linux-x86_64.tar.xz -C ./build/
RUN unzip ./build/Zotero_linux-x86_64/app/omni.ja -d ./omni
ARG HOST_DS
ARG HOST_ST
RUN set -eux; \
        sed -i "s#https://api.zotero.org/#$HOST_DS#g" ./omni/resource/config.mjs; \
        sed -i "s#wss://stream.zotero.org/#$HOST_ST#g" ./omni/resource/config.mjs; \
        perl -i -pe "s#https://www\.zotero\.org/(?!start)#$HOST_DS#g" ./omni/resource/config.mjs; \
        sed -i "s#https://zoteroproxycheck.s3.amazonaws.com/test##g" ./omni/resource/config.mjs
RUN cd omni && 7z a -r ../omni.zip *
RUN cp omni.zip ./build/Zotero_linux-x86_64/app/omni.ja

FROM scratch AS export-stage
COPY --from=intermediate /usr/app/build .