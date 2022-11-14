FROM openjdk:11

ENV GOSU_VERSION=1.12 \
    SWARM_VERSION=3.36 \
    MD5=9a69b245d815f7942b3b841a32f6d7bd \
    OPENSSL_CONF=/etc/ssl/

# grab gosu for easy step-down from root
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates wget bzip2 python npm \
 && rm -rf /var/lib/apt/lists/* \
 && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
 && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
 && export GNUPGHOME="$(mktemp -d)" \
 && GPG_KEYS=B42F6819007F00F88E364FD4036A9C25BF357DD4 \
 && gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$GPG_KEYS" \
  || gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEYS" \
  || gpg --keyserver pgp.mit.edu --recv-keys "$GPG_KEYS" \
  || gpg --keyserver keyserver.pgp.com --recv-keys "$GPG_KEYS" \
 && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
 && rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
 && chmod +x /usr/local/bin/gosu \
 && gosu nobody true

# Python virtualenv
RUN curl "https://bootstrap.pypa.io/pip/2.7/get-pip.py" -o "/tmp/get-pip.py" \
 && python /tmp/get-pip.py \
 && pip install virtualenv \
 && rm /tmp/get-pip.py

# grab swarm-client.jar
RUN mkdir -p /var/jenkins_home \
 && useradd -d /var/jenkins_home/worker -u 1000 -m -s /bin/bash jenkins \
 && curl -o /bin/swarm-client.jar -SL https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/$SWARM_VERSION/swarm-client-$SWARM_VERSION.jar \
 && echo "$MD5  /bin/swarm-client.jar" | md5sum -c - \
 && mkdir -p ~/.ssh \
 && ssh-keyscan github.com >> ~/.ssh/known_hosts

COPY docker-entrypoint.sh /

VOLUME /var/jenkins_home/worker
WORKDIR /var/jenkins_home/worker

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["java", "-jar", "/bin/swarm-client.jar"]
