FROM openjdk:8

ENV GOSU_VERSION=1.11 \
    SWARM_VERSION=3.16 \
    MD5=c1f4b73a83075b51b42f0e8f3a615c50 \
    PHANTOMJS_VERSION=phantomjs-2.1.1-linux-x86_64 \
    MD5PHANTOMJS=1c947d57fce2f21ce0b43fe2ed7cd361  \
    CASPERJS_VERSION=1.1.4-2

# grab gosu for easy step-down from root
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates wget bzip2 python \
 && rm -rf /var/lib/apt/lists/* \
 && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
 && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
 && export GNUPGHOME="$(mktemp -d)" \
 && GPG_KEYS=B42F6819007F00F88E364FD4036A9C25BF357DD4 \
 && gpg --keyserver hkp://:p80.pool.sks-keyservers.net:80 --recv-keys "$GPG_KEYS" \
  || gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEYS" \
  || gpg --keyserver pgp.mit.edu --recv-keys "$GPG_KEYS" \
  || gpg --keyserver keyserver.pgp.com --recv-keys "$GPG_KEYS" \
 && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
 && rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
 && chmod +x /usr/local/bin/gosu \
 && gosu nobody true

# Python virtualenv
RUN curl "https://bootstrap.pypa.io/get-pip.py" -o "/tmp/get-pip.py" \
 && python /tmp/get-pip.py \
 && pip install virtualenv \
 && rm /tmp/get-pip.py

# PhantomJS
RUN wget --no-check-certificate https://bitbucket.org/ariya/phantomjs/downloads/$PHANTOMJS_VERSION.tar.bz2 \
 && echo "$MD5PHANTOMJS  ${PHANTOMJS_VERSION}.tar.bz2" | md5sum -c - \
 && tar xvf ${PHANTOMJS_VERSION}.tar.bz2 \
 && mv $PHANTOMJS_VERSION/bin/phantomjs /usr/local/bin/ \
 && rm -rf phantom*

# CasperJS
RUN git clone  -b ${CASPERJS_VERSION}  git://github.com/casperjs/casperjs.git \
 && mv casperjs /opt/ \
 && ln -sf /opt/casperjs/bin/casperjs /usr/local/bin/casperjs

# grab swarm-client.jar
RUN mkdir -p /var/jenkins_home \
 && useradd -d /var/jenkins_home/worker -u 1000 -m -s /bin/bash jenkins \
 && curl -o /bin/swarm-client.jar -SL https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/$SWARM_VERSION/swarm-client-$SWARM_VERSION.jar \
 && echo "$MD5  /bin/swarm-client.jar" | md5sum -c -

COPY docker-entrypoint.sh /

VOLUME /var/jenkins_home/worker
WORKDIR /var/jenkins_home/worker

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["java", "-jar", "/bin/swarm-client.jar"]
