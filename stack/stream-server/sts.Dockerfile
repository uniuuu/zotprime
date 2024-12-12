FROM node:10-alpine
ARG ZOTPRIME_VERSION=2

RUN apk add --update --no-cache \
libc6-compat

RUN cp /lib64/ld-linux-x86-64.so.2 /lib

WORKDIR /usr/src/app
COPY ./stream-server/ .
COPY config/default.js /usr/src/app/config/
RUN npm install
EXPOSE 81/TCP
CMD [ "npm", "start" ]