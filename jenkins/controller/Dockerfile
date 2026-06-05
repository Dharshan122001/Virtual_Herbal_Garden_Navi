FROM jenkins/jenkins:lts-jdk17

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    docker.io \
    git \
    && rm -rf /var/lib/apt/lists/*

COPY jenkins/controller/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

COPY jenkins/controller/casc/jenkins.yaml /usr/share/jenkins/ref/jenkins.yaml
COPY jenkins/agent /usr/share/jenkins/ref/agent-image
COPY jenkins/controller/entrypoint.sh /usr/local/bin/jenkins-entrypoint.sh
RUN chmod +x /usr/local/bin/jenkins-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/jenkins-entrypoint.sh"]
