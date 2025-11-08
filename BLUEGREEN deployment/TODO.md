# Remaining Steps for Blue-Green Deployment Lab

The repository now contains all source code, Docker assets, Jenkins pipeline, helper scripts, and documentation. To finish the lab, complete the environment-specific tasks below:

1. **Provision / prepare the target host**
   - Install Docker Engine + Compose v2, and Nginx.
   - Copy the contents of `BLUEGREEN deployment/` (compose files, nginx template, scripts) to `/opt/bluegreen` (or update `REMOTE_PATH` in the Jenkinsfile to match wherever you place them).
   - Ensure the SSH user you plan to use can run Docker commands and reload Nginx (add to the `docker` group, configure sudo if needed).

2. **Docker Hub setup**
   - Create the Docker Hub repository you want to push to (e.g. `docker.io/<user>/bluegreen-demo`).
   - Update `DOCKER_IMAGE` inside `BLUEGREEN deployment/Jenkinsfile` with that repository name.

3. **Jenkins credentials**
   - `docker-hub-creds`: Docker Hub username/password.
   - `bluegreen-ssh-key`: SSH private key for the deployment host.
   - `bluegreen-ssh-host`: secret text containing `user@hostname`.
   - Adjust credential IDs in the Jenkinsfile if your IDs differ.

4. **Jenkins pipeline job**
   - Create a Pipeline job that uses `BLUEGREEN deployment/Jenkinsfile`.
   - Configure parameters: `TARGET_COLOR` (blue/green), `SWITCH_TRAFFIC` (boolean), `APP_VERSION` (optional tag).
   - Make sure the Jenkins agent has Docker and Node.js 18.

5. **First deployment (blue)**
   - Run the pipeline with `TARGET_COLOR=blue`, `SWITCH_TRAFFIC=true`.
   - Verify: `http://<load-balancer>` should serve the blue app (port 8081 behind Nginx).

6. **Second deployment (green)**
   - Run again with `TARGET_COLOR=green` and an updated `APP_VERSION`.
   - Once tests pass, keep `SWITCH_TRAFFIC=true` to redirect users to the green stack (port 8082).

7. **Screenshots for submission**
   - Jenkins stage view + console output.
   - Docker Hub repository showing pushed tags.
   - Blue/green endpoints and `switch_traffic.sh` evidence (nginx config / health checks).
   - Any other proofs requested in your assignment brief.

8. **Optional**
   - Implement automated smoke tests before switching traffic.
   - Add Slack/email notifications to the Jenkins `post` block.

Once these steps are done, capture the required screenshots and submit along with this repository.
