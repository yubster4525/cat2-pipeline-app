# Blue-Green Deployment Procedure

1. **Prepare Jenkins**
   - Install Docker, Node.js 18+, and Git on the Jenkins agent.
   - Create credentials:
     - `docker-hub-creds` (Docker Hub username/password).
     - `bluegreen-ssh-key` (SSH private key for the deployment host).
     - `bluegreen-ssh-host` (Secret text of `user@public-ip`).

2. **Prepare the Deployment Host**
   - Install Docker Compose v2 and Nginx.
   - Create `/opt/bluegreen` and copy `docker-compose.blue.yml`, `docker-compose.green.yml`, `nginx/default.conf.template`, and both helper scripts to that path.
   - Ensure the user from `bluegreen-ssh-host` can run Docker and reload Nginx.

3. **Build & Test Locally (optional)**
   - `cd "BLUEGREEN deployment" && docker build -t bluegreen-demo:dev .`
   - `docker compose -f docker-compose.blue.yml up -d` to verify the blue stack.

4. **Create the Jenkins Pipeline Job**
   - Point the job to `BLUEGREEN deployment/Jenkinsfile`.
   - Add parameters `TARGET_COLOR`, `SWITCH_TRAFFIC`, `APP_VERSION` (defaults already defined in the file).
   - Update the `DOCKER_IMAGE` constant in the Jenkinsfile to your Docker Hub repo.

5. **Deploy the First Release (Blue)**
   - Run the pipeline with `TARGET_COLOR=blue`.
   - Jenkins runs npm install/test, builds the Docker image, pushes it to Docker Hub, and executes `scripts/deploy_color.sh` for blue (port `8081`).
   - After verification, keep `SWITCH_TRAFFIC=true` so `switch_traffic.sh` rewrites `/etc/nginx/conf.d/bluegreen.conf` to point to port `8081` and reloads Nginx.

6. **Deploy the Second Release (Green)**
   - Run the pipeline again with `TARGET_COLOR=green` (optionally a new `APP_VERSION`).
   - The pipeline deploys the green stack on port `8082`, leaving blue untouched.
   - Once smoke tests pass, keep `SWITCH_TRAFFIC=true` to point Nginx to green (port `8082`).

7. **Subsequent Releases**
   - Alternate colors for every run. The inactive color acts as the rollback target.
   - Rollback by re-running the pipeline with the previous color and `SWITCH_TRAFFIC=true`.

8. **Monitoring & Cleanup**
   - Use `docker compose -f docker-compose.<color>.yml ps` on the remote host to view containers.
   - Old containers remain available; remove them with `docker compose -f docker-compose.<color>.yml down` when they're no longer needed.

This procedure, combined with the Jenkinsfile and helper scripts, ensures zero-downtime releases using the blue-green strategy.
