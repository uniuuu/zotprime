# syntax=docker/dockerfile:1
FROM node:lts-alpine
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

WORKDIR /usr/src/app
COPY ./tinymce-clean-server .
RUN npm install

# Fix permissions for non-root user
RUN chown -R node:node /usr/src/app

# Switch to non-root user
USER node

EXPOSE 16342

CMD [ "npm", "start" ]
