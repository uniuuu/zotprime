
############################
# memcached image
############################

FROM memcached:1-alpine

USER root
RUN apk add --no-cache netcat-openbsd
USER memcache