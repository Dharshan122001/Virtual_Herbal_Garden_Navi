FROM jenkins/inbound-agent:latest-jdk17

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    gnupg \
    lsb-release \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Dynamic Helm Installation based on native container architecture
RUN arch="$(dpkg --print-architecture)" \
    && curl -fsSL "https://get.helm.sh/helm-v3.16.3-linux-${arch}.tar.gz" -o /tmp/helm.tgz \
    && tar -xzf /tmp/helm.tgz -C /tmp \
    && mv /tmp/linux-${arch}/helm /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm \
    && rm -rf /tmp/helm.tgz /tmp/linux-${arch}

# Dynamic Kubectl Installation based on native container architecture
RUN arch="$(dpkg --print-architecture)" \
    && curl -fsSL "https://dl.k8s.io/release/stable.txt" -o /tmp/k8s-version \
    && KUBECTL_VERSION="$(cat /tmp/k8s-version)" \
    && curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${arch}/kubectl" \
    && chmod +x /usr/local/bin/kubectl \
    && rm -f /tmp/k8s-version

# Dynamic Docker CLI Installation mapping amd64 -> x86_64 and arm64 -> aarch64
RUN arch="$(dpkg --print-architecture)" \
    && case "$arch" in \
      amd64) docker_arch="x86_64" ;; \
      arm64) docker_arch="aarch64" ;; \
      *) echo "Unsupported architecture: $arch" && exit 1 ;; \
    esac \
    && curl -fsSL "https://download.docker.com/linux/static/stable/${docker_arch}/docker-27.3.1.tgz" -o /tmp/docker.tgz \
    && tar -xzf /tmp/docker.tgz -C /tmp \
    && mv /tmp/docker/docker /usr/local/bin/docker \
    && chmod +x /usr/local/bin/docker \
    && rm -rf /tmp/docker.tgz /tmp/docker

USER root