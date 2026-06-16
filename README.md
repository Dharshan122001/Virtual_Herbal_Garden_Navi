# Virtual Herbal Garden

Virtual Herbal Garden is a full-stack application for exploring medicinal plants, identifying plants from images, and chatting with an AI herbal assistant.

## What This Repo Uses

- Frontend: React + Vite
- Backend: FastAPI microservices
- Database: PostgreSQL
- Deployment: Jenkins + Kubernetes + Helm
- Infrastructure: Terraform for AKS, ingress, and monitoring

## Deployment Model

The old Argo CD flow has been removed from the active path.

The new flow is:

1. Jenkins checks out the repo.
2. Jenkins detects which service paths changed.
3. Jenkins builds and pushes only the changed Docker images.
4. Jenkins deploys the Helm chart directly to Kubernetes with `helm upgrade --install`.
5. Kubernetes serves the frontend and backend through Nginx ingress.

## Main Files

- [Jenkinsfile](./Jenkinsfile)
- [Helm chart](./vhg-chart)
- [Terraform K8s setup](./K8s)

## Jenkins Setup

Before running the pipeline, create these Jenkins credentials:

- `dockerhub-creds` for Docker Hub username/password
- `aks-kubeconfig` for the Kubernetes kubeconfig text

Then make sure the Jenkins agent has:

- Docker
- Helm
- kubectl

## Shared Library

The pipeline now lives in a Jenkins shared-library style file:

- [vars/vhgPipeline.groovy](./vars/vhgPipeline.groovy)

To use it in Jenkins, register a global pipeline library named `vhg-shared-library` and point it at this repository.

Then the top-level [Jenkinsfile](./Jenkinsfile) can stay tiny and simply call `vhgPipeline()`.

## Installing Jenkins

If you do not already have Jenkins, the quickest POC setup is Docker Compose:

```bash
docker compose up -d --build
```

The controller will start, bootstrap the local agent image, and configure the Docker cloud automatically. The first run can take a little longer because Jenkins is building its own agent image locally.
The controller will start Jenkins directly. It no longer tries to build an agent image during startup, which avoids the restart loop you hit.

Open:

```text
http://localhost:8080
```

To get the first admin password:

```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

After login, install these Jenkins plugins:

- Pipeline
- Git
- Credentials Binding
- Docker Pipeline
- Workspace Cleanup

The controller image already preinstalls those plugins, so this section is mostly a sanity check if you change the image later.

## How The Agent Works

The repo still includes a reusable agent image at:

- [jenkins/agent/Dockerfile](./jenkins/agent/Dockerfile)

For now the pipeline runs on the built-in Jenkins executor so you can get moving immediately. The agent image is still in the repo if you want to switch to a dedicated build node later.

The agent image includes:

- Docker
- Helm
- kubectl

## First-Time Setup Notes

- The controller still uses the normal Jenkins first-login password flow.
- The Docker socket from the host is mounted into the controller so Jenkins can create agents and the agent can build and push images.
- If you need to rebuild everything from scratch, just remove the Jenkins volume and run `docker compose up -d` again.
- For `aks-kubeconfig`, use `Kind: Secret text` and paste the full contents of your `~/.kube/config` file into the credential value.

## How The Pipeline Deploys

The pipeline uses the existing Helm chart in `vhg-chart/` and sets a build tag only for the services that changed:

- `frontend`
- `plant-service`
- `auth-service`
- `ai-service`

The chart already defines the Kubernetes deployments, services, ingress, and secret required by the app.

If only chart files change, Jenkins still re-runs `helm upgrade --install` so Kubernetes picks up the chart updates even when no image rebuild is needed.

## Local Notes

If you want to inspect the app locally, the frontend is in `client/` and the backend services are in `server/`.

If you want, I can also help you with:

1. A Jenkins job configuration step-by-step.
2. Moving the hardcoded secrets in the Helm chart into safer Kubernetes secrets.
3. Creating a `values-jenkins.yaml` file for cleaner image overrides.
