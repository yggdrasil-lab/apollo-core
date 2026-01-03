#!/bin/bash
set -e
# Usage: ./scripts/deploy.sh <STACK_NAME> [COMPOSE_FILES...]

# Create required directories for bind mounts
# NOTE: Ensure these directories exist on the target node (muspelheim) manually!
# Run on Manager (Gaia):
# sudo mkdir -p /opt/apollo-core/{tautulli,prowlarr,overseerr}
#
# Run on Worker (Muspelheim):
# sudo mkdir -p /opt/apollo-core/{plex,jellyfin,sonarr,radarr,lidarr} /mnt/storage/media

./scripts/deploy.sh --skip-build "apollo-core" docker-compose.yml
