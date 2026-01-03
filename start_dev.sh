#!/bin/bash
set -e
source ./scripts/load_env.sh
export PLACEMENT_CONSTRAINT="node.role == manager"

# Create required directories for bind mounts
echo "Ensuring bind mount directories exist..."
sudo mkdir -p /opt/apollo-core/{plex,jellyfin,tautulli,sonarr,radarr,lidarr,prowlarr,overseerr} /mnt/storage/media/{TV,Movies,Music,Audiobooks}
sudo chown -R 1000:1000 /opt/apollo-core /mnt/storage/media

./scripts/deploy.sh --skip-build "apollo-core-dev" docker-compose.yml
