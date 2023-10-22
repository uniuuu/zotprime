#!/bin/bash
set -ex

#chmod -R 764 /usr/share/elasticsearch/.aws/config/*

sysctl -w vm.max_map_count=262144

exec "$@"