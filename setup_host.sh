#!/bin/bash

# setup_host.sh
# This script prepares the host directories for the Apollo Core stack.
# Usage: ./setup_host.sh via SSH on the target node (Muspelheim/Manager)

echo "Setting up Apollo Core directories..."

# config directories
echo "Creating /opt/apollo-core config directories..."
sudo mkdir -p /opt/apollo-core/{plex,jellyfin,tautulli,sonarr,radarr,lidarr,prowlarr,overseerr,lazylibrarian}

# media directories
echo "Creating /mnt/storage/media directories..."
sudo mkdir -p /mnt/storage/media/{Movies,TV,Music,Audiobooks,Books}
sudo mkdir -p /mnt/storage/downloads
sudo mkdir -p /mnt/storage/backups/apollo/{sonarr,radarr,lidarr,prowlarr}

# permissions
echo "Setting ownership to 1000:1000..."
sudo chown -R 1000:1000 /opt/apollo-core
sudo chown -R 1000:1000 /mnt/storage/media
sudo chown -R 1000:1000 /mnt/storage/downloads
sudo chown -R 1000:1000 /mnt/storage/backups/apollo

echo "Done. Host is ready for deployment."
