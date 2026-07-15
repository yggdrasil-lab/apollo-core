#!/bin/bash
set -e

# setup_host_gaia.sh
# This script prepares the Gaia host directories for the Apollo Core services that run on Managers.
# Usage: ./setup_host_gaia.sh via SSH on the target node (Gaia)

echo "Setting up Apollo Core directories on Gaia..."

# Local Config Directories
SERVICES=("jellystat" "jellystat-db" "prowlarr" "seerr" "recyclarr")
for service in "${SERVICES[@]}"; do
    DIR="/opt/apollo-core/${service}"
    if [ ! -d "${DIR}" ]; then
        echo "Creating ${DIR}..."
        sudo mkdir -p "${DIR}"
        sudo chown -R 1000:1000 "${DIR}"
    fi
done

# Backup Directory for Prowlarr (runs on Gaia Manager)
BACKUP_DIR="/mnt/storage/backups/apollo/prowlarr"
if [ ! -d "${BACKUP_DIR}" ]; then
    echo "Creating ${BACKUP_DIR}..."
    sudo mkdir -p "${BACKUP_DIR}"
    sudo chown -R 1000:1000 "${BACKUP_DIR}"
fi

echo "Done. Gaia is ready for deployment."
