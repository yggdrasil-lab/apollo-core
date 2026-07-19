#!/bin/bash
set -e

# setup_host_muspelheim.sh
# This script prepares the Muspelheim host directories for the Apollo Core stack.
# Usage: ./setup_host_muspelheim.sh via SSH on the target node (Muspelheim)

echo "Setting up Apollo Core directories on Muspelheim..."

# Config Directories (Muspelheim hosts the majority of the media apps)
SERVICES=("jellyfin" "sonarr" "radarr" "lidarr" "audiobookshelf" "bazarr")
for service in "${SERVICES[@]}"; do
    DIR="/opt/apollo-core/${service}"
    if [ ! -d "${DIR}" ]; then
        echo "Creating ${DIR}..."
        sudo mkdir -p "${DIR}"
        sudo chown -R 1000:1000 "${DIR}"
    fi
done

# Media Directories (Muspelheim is the storage giant)
MEDIA_SUBDIRS=("Movies" "TV" "Music" "Audiobooks" "Books" "Youtube/audio" "Youtube/video")
for subdir in "${MEDIA_SUBDIRS[@]}"; do
    DIR="/mnt/storage/media/${subdir}"
    if [ ! -d "${DIR}" ]; then
        echo "Creating ${DIR}..."
        sudo mkdir -p "${DIR}"
        sudo chown -R 1000:1000 "${DIR}"
    fi
done

# Downloads Directory
if [ ! -d "/mnt/storage/downloads" ]; then
    echo "Creating /mnt/storage/downloads..."
    sudo mkdir -p /mnt/storage/downloads
    sudo chown -R 1000:1000 /mnt/storage/downloads
fi

# Backup Directories
BACKUP_SERVICES=("sonarr" "radarr" "lidarr" "prowlarr" "audiobookshelf" "bazarr")
for service in "${BACKUP_SERVICES[@]}"; do
    DIR="/mnt/storage/backups/apollo/${service}"
    if [ ! -d "${DIR}" ]; then
        echo "Creating ${DIR}..."
        sudo mkdir -p "${DIR}"
        sudo chown -R 1000:1000 "${DIR}"
    fi
done

echo "Done. Muspelheim is ready for deployment."
