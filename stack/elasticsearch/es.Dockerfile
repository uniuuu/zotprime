
############################
# elasticsearch image
############################

#   image: docker.elastic.co/elasticsearch/elasticsearch:5.3.0
#FROM docker.elastic.co/elasticsearch/elasticsearch:8.7.0
FROM docker.elastic.co/elasticsearch/elasticsearch:8.10.2


#ENTRYPOINT  sysctl -w vm.max_map_count=262144; su elasticsearch -c bin/elasticsearch

#ENTRYPOINT ["/bin/sh", "-c" , "sysctl -w vm.max_map_count=262144 ; /bin/tini -- /usr/local/bin/docker-entrypoint.sh"]
# Dummy overridable parameter parsed by entrypoint
#CMD ["eswrapper"]
#USER 1000:0
#USER root

#COPY entrypoint.sh /entrypoint.sh
#RUN ["chmod", "+x", "/entrypoint.sh"]
#ENTRYPOINT ["/entrypoint.sh"]

#USER 1000:0
#CMD ["su", "elasticsearch", "-c", "bin/elasticsearch"]
#CMD ["/bin/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]

