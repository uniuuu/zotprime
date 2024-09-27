FROM alpine:3 AS intermediate
ARG ZOTPRIME_VERSION=2

RUN set -eux; \ 
    apk update && apk upgrade && \
    apk add --update --no-cache \
    curl \
    zip \
    7zip \
    && rm -rf /var/cache/apk/*
WORKDIR /usr/app
RUN mkdir /usr/app/build
RUN curl -sSO https://download.zotero.org/client/release/7.0.5/Zotero-7.0.5_linux-x86_64.tar.bz2
RUN tar -xjf Zotero-7.0.5_linux-x86_64.tar.bz2 -C ./build/
RUN unzip ./build/Zotero_linux-x86_64/app/omni.ja -d ./omni
ARG HOST_DS
ARG HOST_ST
RUN set -eux; \
        sed -i "s#https://api.zotero.org/#$HOST_DS#g" ./omni/resource/config.js; \
        sed -i "s#wss://stream.zotero.org/#$HOST_ST#g" ./omni/resource/config.js; \
        sed -i "s#https://www.zotero.org/#$HOST_DS#g" ./omni/resource/config.js; \
        sed -i "s#https://zoteroproxycheck.s3.amazonaws.com/test##g" ./omni/resource/config.js
RUN cd omni && 7z a -r ../omni.zip *
RUN cp omni.zip ./build/Zotero_linux-x86_64/app/omni.ja

FROM scratch AS export-stage
COPY --from=intermediate /usr/app/build .