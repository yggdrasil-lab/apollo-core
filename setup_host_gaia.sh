#!/bin/bash

# setup_host_gaia.sh
# This script prepares the Gaia host directories for the Apollo Core services that run on Managers.
# Usage: ./setup_host_gaia.sh via SSH on the target node (Gaia)

echo "Setting up Apollo Core directories on Gaia..."

# config directories - Gaia hosts lighter services or manager-only services
# Based on docker-compose.yml constraints: Tautulli, Prowlarr, Overseerr are often on manager or general nodes.
# Checking docker-compose:
# - Tautulli: constraints: [ "node.role == manager" ]
# - Prowlarr: constraints: [ "node.role == manager" ]
# - Overseerr: constraints: [ "node.role == manager" ]
# - Plex: constraints: [ "node.hostname == muspelheim" ] (Wait, Plex is usually on Muspelheim in previous file, let's verify)

# Upon re-reading docker-compose.yml:
# - Plex: node.hostname == muspelheim
# - Jellyfin: node.hostname == muspelheim
# - Tautulli: node.role == manager
# - Sonarr/Radarr/Lidarr: node.hostname == muspelheim
# - Prowlarr: node.role == manager
# - Overseerr: node.role == manager
# - LazyLibrarian: node.hostname == muspelheim
# - Audiobookshelf: node.hostname == muspelheim

echo "Creating /opt/apollo-core config directories for Manager services..."
sudo mkdir -p /opt/apollo-core/{tautulli,prowlarr,overseerr}

# permissions
echo "Setting ownership to 1000:1000..."
sudo chown -R 1000:1000 /opt/apollo-core

echo "Done. Gaia is ready for deployment."
