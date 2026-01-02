#!/bin/bash
set -e
# Usage: ./scripts/deploy.sh <STACK_NAME> [COMPOSE_FILES...]

# Create required directories for bind mounts
# NOTE: Ensure these directories exist on the target node (muspelheim) manually!
# sudo mkdir -p /opt/apollo-core/{plex,jellyfin,tautulli,sonarr,radarr,lidarr,readarr,prowlarr,overseerr} /mnt/storage/media

./scripts/deploy.sh --skip-build "apollo-core" docker-compose.yml
