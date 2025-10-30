FROM eclipse-temurin:17-jre-focal

ENV SWARM_VERSION=3.49 \
    MD5=6bfae61d1c500fbe156c62ae3a8ac56c 

#same versions as eeacms/gitflow
ENV YQ_VERSION=v4.48.1
ENV JQ_VERSION=1.6


# grab gosu for easy step-down from root
RUN apt-get update \
 && apt-get install -y --no-install-recommends ssh ca-certificates wget bzip2 python npm make gosu git \
 && curl -L -o /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64 \
 && chmod 755 /usr/bin/jq \
 && wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64.tar.gz -O - | tar xz \
 && mv yq_linux_amd64 /usr/bin/yq \
 && rm -rf /var/lib/apt/lists/* \
 && gosu nobody true \
# Python virtualenv
 && curl "https://bootstrap.pypa.io/pip/2.7/get-pip.py" -o "/tmp/get-pip.py" \
 && python /tmp/get-pip.py \
 && pip install virtualenv \
 && rm /tmp/get-pip.py \
# grab swarm-client.jar
 && mkdir -p /var/jenkins_home \
 && useradd -d /var/jenkins_home/worker -u 1000 -m -s /bin/bash jenkins \
 && curl -o /bin/swarm-client.jar -SL https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/$SWARM_VERSION/swarm-client-$SWARM_VERSION.jar \
 && echo "$MD5  /bin/swarm-client.jar" | md5sum -c - \
 && mkdir -p ~/.ssh \
 && ssh-keyscan github.com >> ~/.ssh/known_hosts \
 && mkdir -p /var/jenkins_home/worker/.ssh \
 && ssh-keyscan github.com >> /var/jenkins_home/worker/.ssh/known_hosts \
 && chmod 644 /var/jenkins_home/worker/.ssh/known_hosts \
 && chown -R jenkins:jenkins /var/jenkins_home/worker/.ssh
 

COPY docker-entrypoint.sh /

VOLUME /var/jenkins_home/worker
WORKDIR /var/jenkins_home/worker

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["java", "-jar", "/bin/swarm-client.jar"]
