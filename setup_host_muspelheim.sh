#!/bin/bash

# setup_host_muspelheim.sh
# This script prepares the Muspelheim host directories for the Apollo Core stack.
# Usage: ./setup_host_muspelheim.sh via SSH on the target node (Muspelheim)

echo "Setting up Apollo Core directories on Muspelheim..."

# config directories - Muspelheim hosts the majority of the media apps
echo "Creating /opt/apollo-core config directories..."
sudo mkdir -p /opt/apollo-core/{plex,jellyfin,sonarr,radarr,lidarr,lazylibrarian,audiobookshelf}

# media directories - Muspelheim is the storage giant
echo "Creating /mnt/storage/media directories..."
sudo mkdir -p /mnt/storage/media/{Movies,TV,Music,Audiobooks,Books,Youtube/{audio,video}}
sudo mkdir -p /mnt/storage/downloads
sudo mkdir -p /mnt/storage/backups/apollo/{sonarr,radarr,lidarr,prowlarr,audiobookshelf}

# permissions
echo "Setting ownership to 1000:1000..."
sudo chown -R 1000:1000 /opt/apollo-core
sudo chown -R 1000:1000 /mnt/storage/media
sudo chown -R 1000:1000 /mnt/storage/downloads
sudo chown -R 1000:1000 /mnt/storage/backups/apollo

echo "Done. Muspelheim is ready for deployment."
