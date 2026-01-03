#!/bin/sh
set -eux


#export APACHE_RUN_USER=${RUN_USER}

#(until rinetd -f -c /etc/rinetd.conf; do
#    echo "'rinetd' crashed with exit code $?. Restarting..." >&2
#    sleep 1
#done) & 

#exec httpd -e debug -DFOREGROUND -k start

if [ -e tmp/_key/secret-minio.txt ]
then
    source tmp/_key/secret-minio.txt
fi  

echo "Waiting for MinIO to be ready..."
until /usr/bin/mc alias set minio http://minio:9000 ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD} 2>/dev/null && \
      /usr/bin/mc ready minio --insecure 2>/dev/null
do
  echo -n .
  sleep 2
done
echo "MinIO is ready"

# Configure trace based on env var (default: none)
case "${MINIO_TRACE_LEVEL:-none}" in
    verbose)
        exec mc admin trace -v -a minio
        ;;
    all)
        exec mc admin trace -a minio
        ;;
    errors)
        exec mc admin trace --errors minio
        ;;
    api)
        exec mc admin trace minio
        ;;
    none|*)
        exec tail -f /dev/null
        ;;
esac
