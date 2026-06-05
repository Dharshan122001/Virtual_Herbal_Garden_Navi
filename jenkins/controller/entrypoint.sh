#!/bin/bash
set -euo pipefail

AGENT_IMAGE="vhg-jenkins-agent:latest"
AGENT_CONTEXT="/usr/share/jenkins/ref/agent-image"

if ! docker image inspect "$AGENT_IMAGE" >/dev/null 2>&1; then
  echo "Building Jenkins agent image: $AGENT_IMAGE"
  docker build -t "$AGENT_IMAGE" "$AGENT_CONTEXT"
fi

exec /usr/local/bin/jenkins.sh "$@"
