# Blue-Green Deployment Lab

This lab shows how to containerize a simple Node.js service, push the image to Docker Hub, and wire a Jenkins pipeline that deploys the service in **blue** or **green** environments with zero downtime. After verification, traffic is switched through an Nginx reverse proxy.

## Repository Layout

```
BLUEGREEN deployment/
├── README.md                 # You are here
├── Jenkinsfile               # Pipeline used in Jenkins
├── Dockerfile                # Builds the Node.js container image
├── app/                      # Sample Node.js application
├── docker-compose.blue.yml   # Compose file for the blue stack (port 8081)
├── docker-compose.green.yml  # Compose file for the green stack (port 8082)
├── nginx/default.conf.template
└── scripts/
    ├── deploy_color.sh       # SSH helper to deploy blue/green
    └── switch_traffic.sh     # SSH helper to point Nginx at the active color
```

## Prerequisites

- Jenkins agent with Docker CLI, Node.js 18+, and SSH access to the target host.
- Docker Hub account and credentials stored in Jenkins (`docker-hub-creds`).
- SSH credentials for the deployment host (`bluegreen-ssh-key` for the private key and `bluegreen-ssh-host` storing `user@hostname`).
- Remote host prepared with Docker Compose v2, `/opt/bluegreen` containing the compose files, nginx template, and write access to `/etc/nginx/conf.d`.

## Node.js Application

The sample app (`app/src/server.js`) exposes `/` and `/health` endpoints. The home page shows the color and version:

```bash
cd "BLUEGREEN deployment/app"
npm install
npm start
```

Set `APP_COLOR` and `APP_VERSION` to preview blue vs. green pages locally.

## Building and Running Locally

```bash
# Build the container image
cd "BLUEGREEN deployment"
docker build -t bluegreen-demo:dev .

# Run blue environment on port 8081
docker compose -f docker-compose.blue.yml up -d --build

# Run green environment on port 8082
docker compose -f docker-compose.green.yml up -d --build
```

Visit `http://localhost:8081` and `http://localhost:8082` to see each color. The Nginx template (`nginx/default.conf.template`) is used by `switch_traffic.sh` to update `/etc/nginx/conf.d/bluegreen.conf` with the correct upstream port.

## Jenkins Pipeline Overview

Stages in `Jenkinsfile`:

1. **Checkout** – Pulls the repo.
2. **Resolve Metadata** – Sets the Docker tag (`APP_VERSION` parameter or `GIT_COMMIT[0:7]`).
3. **Install Dependencies / Unit Tests** – Runs `npm install && npm test` inside the app directory.
4. **Docker Build** – Builds `DOCKER_IMAGE:tag` using the Dockerfile in this folder.
5. **Push to Docker Hub** – Logs in with `docker-hub-creds` and pushes the tag.
6. **Deploy Target Color** – Calls `scripts/deploy_color.sh` with `TARGET_COLOR` to pull & run the container on the remote host (blue = port 8081, green = port 8082).
7. **Switch Traffic (optional)** – If `SWITCH_TRAFFIC` is true, `scripts/switch_traffic.sh` rewrites the Nginx config to point to the freshly deployed color and reloads Nginx.

Parameters:

- `TARGET_COLOR`: *blue* or *green*.
- `SWITCH_TRAFFIC`: defaults to true, can be disabled for staging.
- `APP_VERSION`: optional tag override.

## Helper Scripts

### `deploy_color.sh`

- Requires env vars `COLOR`, `DOCKER_IMAGE`, `REMOTE_HOST`, and `REMOTE_PATH`.
- SSHes into the remote host and runs `docker compose -f docker-compose.COLOR.yml pull && up -d` with `DOCKER_IMAGE` exported.

### `switch_traffic.sh`

- Needs `ACTIVE_COLOR`, `REMOTE_HOST`, `REMOTE_PATH`, optional `NGINX_RELOAD_COMMAND`.
- Renders `nginx/default.conf.template` with the port (8081=blue, 8082=green) and moves it to `/etc/nginx/conf.d/bluegreen.conf`, then reloads Nginx.

## Procedure (for submission)

1. Clone the repo and inspect the `BLUEGREEN deployment` folder.
2. Configure Jenkins credentials: Docker Hub (`docker-hub-creds`), `bluegreen-ssh-key` (private key), and `bluegreen-ssh-host` (secret text like `ubuntu@54.1.2.3`).
3. Copy the files in this folder to your remote host under `/opt/bluegreen` and ensure Docker Compose + Nginx are installed. Adjust the compose files if you prefer different ports.
4. Create a Jenkins Pipeline job pointing at this folder’s Jenkinsfile. Add the `TARGET_COLOR`, `SWITCH_TRAFFIC`, and `APP_VERSION` parameters.
5. Run the pipeline with `TARGET_COLOR=blue`. Jenkins builds the image, pushes it, and deploys the blue stack. Access `http://<load-balancer>` to confirm.
6. For the next release, run the pipeline with `TARGET_COLOR=green`. After verification, keep `SWITCH_TRAFFIC=true` to route traffic to green. Blue stays running for quick rollback.
7. Repeat as needed, alternating colors for every release to guarantee zero downtime.

## Notes

- Update `DOCKER_IMAGE` inside the Jenkinsfile to match your Docker Hub repository.
- If your remote host requires sudo for Docker commands, wrap them inside the scripts accordingly.
- Extend `switch_traffic.sh` to run smoke tests before reloading Nginx (curl `/health` once the new port is up).
