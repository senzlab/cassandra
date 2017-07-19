FROM ubuntu:16.04

MAINTAINER Eranga Bandara (erangaeb@gmail.com)

# explicitly set user/group IDs
RUN groupadd -r cassandra --gid=999 && useradd -r -g cassandra --uid=999 cassandra

# install required packages
RUN apt-get update -y
RUN apt-get install -y python-software-properties
RUN apt-get install -y software-properties-common

# install java
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
RUN add-apt-repository -y ppa:webupd8team/java
RUN apt-get update -y
RUN apt-get install -y oracle-java8-installer
RUN rm -rf /var/lib/apt/lists/*
RUN rm -rf /var/cache/oracle-jdk8-installer

# set JAVA_HOME
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# cassandra version
ENV CASSANDRA_VERSION 3.11.0

# install cassandra
RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys A278B781FE4B2BDA  
RUN echo 'deb http://www.apache.org/dist/cassandra/debian 311x main' >> /etc/apt/sources.list.d/cassandra.list
RUN apt-get update \
	&& apt-get install -y cassandra="$CASSANDRA_VERSION" \
	&& rm -rf /var/lib/apt/lists/*

# https://issues.apache.org/jira/browse/CASSANDRA-11661
RUN sed -ri 's/^(JVM_PATCH_VERSION)=.*/\1=25/' /etc/cassandra/cassandra-env.sh

ENV CASSANDRA_CONFIG /etc/cassandra

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

RUN mkdir -p /var/lib/cassandra "$CASSANDRA_CONFIG" \
	&& chown -R cassandra:cassandra /var/lib/cassandra /usr/share/cassandra "$CASSANDRA_CONFIG" \
	&& chmod 777 /var/lib/cassandra /usr/share/cassandra "$CASSANDRA_CONFIG"
VOLUME /var/lib/cassandra

# install curl
RUN apt-get update && apt-get install -y curl

# lucene version
ENV PLUGIN_VERSION 3.11.0.0
RUN curl -LO http://search.maven.org/remotecontent\?filepath\=com/stratio/cassandra/cassandra-lucene-index-plugin/3.11.0.0/cassandra-lucene-index-plugin-3.11.0.0.jar
RUN mv cassandra-lucene-index-plugin-3.11.0.0.jar /usr/share/cassandra/lib

EXPOSE 9042 9160

USER cassandra

CMD ["cassandra", "-f"]
