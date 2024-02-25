FROM node:10.24.1-alpine

# install packages
RUN apk update && apk upgrade --no-cache && apk add --quiet git libc6-compat

# Fix binaries problem of the uws module
RUN cp /lib64/ld-linux-x86-64.so.2 /lib

WORKDIR /stream-server
RUN git clone "https://github.com/zotero/stream-server.git" .
RUN npm install --quiet

EXPOSE 81

CMD ["nodejs", "index.js"]
