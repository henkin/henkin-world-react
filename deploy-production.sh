#!/bin/bash

# Usage: ./deploy-production.sh
# This script deploys the current project to the production server using SSH and docker compose.

set -e

REMOTE_HOST="hserver"
REMOTE_DIR="~/henkin-world-react"
COMPOSE_FILE="docker-compose.portainer.yml"

# 1. Copy project files to the remote server (excluding node_modules, .git, build artifacts)
echo "[1/4] Syncing project files to $REMOTE_HOST:$REMOTE_DIR ..."
rsync -av --delete --exclude='.git' --exclude='node_modules' --exclude='.next' --exclude='test-results' --exclude='playwright-report' . "$REMOTE_HOST:$REMOTE_DIR/"

# 2. Stop any running containers for this project
echo "[2/4] Stopping any running containers ..."
ssh $REMOTE_HOST "cd $REMOTE_DIR && docker compose -f $COMPOSE_FILE down"

# 3. Start containers in detached mode
echo "[3/4] Starting containers ..."
ssh $REMOTE_HOST "cd $REMOTE_DIR && docker compose -f $COMPOSE_FILE up -d --build --force-recreate"

echo "[3.5/4] Restarting Traefik ..."
ssh $REMOTE_HOST "docker restart traefik"

echo "[4/4] Showing container status ..."
ssh $REMOTE_HOST "cd $REMOTE_DIR && docker compose -f $COMPOSE_FILE ps"

# 4. Restart Traefik to pick up new configuration
echo "[4/4] Restarting Traefik ..."
ssh $REMOTE_HOST "docker restart traefik"

echo "[Logs] Streaming logs for henkin-world service. Press Ctrl+C to stop."
ssh $REMOTE_HOST "cd $REMOTE_DIR && docker compose -f $COMPOSE_FILE logs -f henkinworld"

echo "Deployment complete!"
 