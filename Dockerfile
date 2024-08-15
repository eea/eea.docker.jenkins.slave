FROM eclipse-temurin:17-jre-focal

ENV SWARM_VERSION=3.47 \
    MD5=6d1f920040528151e78fd89e55b73f32 

# grab gosu for easy step-down from root
RUN apt-get update \
 && apt-get install -y --no-install-recommends ssh ca-certificates wget bzip2 python npm make gosu jq \
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
