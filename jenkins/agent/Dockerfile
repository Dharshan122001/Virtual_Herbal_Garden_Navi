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

# ── Security Tooling ────────────────────────────────────────────────────────

# Python 3 + pip → Bandit (SAST) + Safety (SCA)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip \
    && pip3 install --no-cache-dir bandit safety \
    && rm -rf /var/lib/apt/lists/*

# Node.js 20 → npm audit (SCA)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Trivy → container + filesystem vulnerability scanning (arch-aware)
RUN arch="$(dpkg --print-architecture)" \
    && TRIVY_VERSION="0.58.1" \
    && trivy_arch="$([ "$arch" = "amd64" ] && echo "64bit" || echo "ARM64")" \
    && curl -fsSL "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-${trivy_arch}.tar.gz" -o /tmp/trivy.tgz \
    && tar -xzf /tmp/trivy.tgz -C /tmp trivy \
    && mv /tmp/trivy /usr/local/bin/trivy \
    && chmod +x /usr/local/bin/trivy \
    && rm -f /tmp/trivy.tgz

# Gitleaks → secret / credential detection (arch-aware)
RUN arch="$(dpkg --print-architecture)" \
    && GITLEAKS_VERSION="8.21.2" \
    && gitleaks_arch="$([ "$arch" = "amd64" ] && echo "x64" || echo "arm64")" \
    && curl -fsSL "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_${gitleaks_arch}.tar.gz" -o /tmp/gitleaks.tgz \
    && tar -xzf /tmp/gitleaks.tgz -C /tmp gitleaks \
    && mv /tmp/gitleaks /usr/local/bin/gitleaks \
    && chmod +x /usr/local/bin/gitleaks \
    && rm -f /tmp/gitleaks.tgz

USER jenkins