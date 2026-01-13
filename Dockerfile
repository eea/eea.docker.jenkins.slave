FROM eclipse-temurin:21-jre-noble

ENV SWARM_VERSION=3.51 \
    MD5=75a09418a10ee3f331e72d73a27e076d 

#same versions as eeacms/gitflow
ENV YQ_VERSION=v4.48.1
ENV JQ_VERSION=1.6

ENV JENKINS_HOME=/var/jenkins_home
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000

# grab gosu for easy step-down from root
RUN apt-get update \
 && apt-get install -y --no-install-recommends ssh ca-certificates wget bzip2 python3 python3-pip python3-virtualenv npm make gosu git \
 && curl -L -o /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64 \
 && chmod 755 /usr/bin/jq \
 && wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64.tar.gz -O - | tar xz \
 && mv yq_linux_amd64 /usr/bin/yq \
 && rm -rf /var/lib/apt/lists/*


RUN usermod -u 1001 ubuntu \
  && groupmod -g 1001 ubuntu \
  && mkdir -p $JENKINS_HOME \
  && chown ${uid}:${gid} $JENKINS_HOME \
  && groupadd -g ${gid} ${group} \
  && useradd -d "$JENKINS_HOME" -u ${uid} -g ${gid} -l -m -s /bin/bash ${user}


 RUN gosu nobody true \
# grab swarm-client.jar
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
