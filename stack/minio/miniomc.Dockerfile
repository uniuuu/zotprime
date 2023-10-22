
############################
# mc image
############################

FROM minio/mc

COPY mc-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]