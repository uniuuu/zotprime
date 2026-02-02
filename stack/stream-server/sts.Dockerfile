# syntax=docker/dockerfile:1
FROM node:22-alpine
ARG ZOTPRIME_VERSION=2

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

RUN apk add --update --no-cache \
libc6-compat

# RUN cp /lib64/ld-linux-x86-64.so.2 /lib

WORKDIR /usr/src/app
COPY ./stream-server/ .
COPY config/default.js /usr/src/app/config/
RUN npm install

# Fix permissions for non-root user
RUN chown -R node:node /usr/src/app

# Switch to non-root user
USER node

EXPOSE 81/tcp
CMD [ "npm", "start" ]