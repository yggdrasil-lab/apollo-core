#!/bin/bash
set -e

BACKUP_DIR="/mnt/storage/backups/apollo/prowlarr"
CONFIG_DIR="/opt/apollo-core/prowlarr"
SERVICE_NAME="apollo_prowlarr"

# Check if run as root/sudo
if ! [ -x "$(command -v docker)" ]; then
  echo "Error: Docker command not found. This script must be run on the Docker host."
  exit 1
fi

echo "Scanning for Prowlarr zip backups in ${BACKUP_DIR}..."
# Find all zip files, sorted by modification time (latest first)
IFS=$'\n' read -r -d '' -a BACKUP_FILES < <(find "${BACKUP_DIR}" -name "*.zip" -type f -printf "%T@ %p\n" 2>/dev/null | sort -nr | cut -d' ' -f2- && printf '\0')

if [ ${#BACKUP_FILES[@]} -eq 0 ]; then
  echo "Error: No Prowlarr zip backup files found in ${BACKUP_DIR}."
  exit 1
fi

# Print available backups
echo "Available backups (latest first):"
LIMIT=10
for i in "${!BACKUP_FILES[@]}"; do
  echo "$((i+1))) $(basename "${BACKUP_FILES[i]}") (${BACKUP_FILES[i]})"
  if [ $((i+1)) -eq $LIMIT ]; then
    break
  fi
done

# Prompt for selection
read -p "Select a backup to restore [1-${#BACKUP_FILES[@]}, default 1]: " SELECTION
SELECTION=${SELECTION:-1}

# Validate selection
if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt "${#BACKUP_FILES[@]}" ]; then
  echo "Invalid selection."
  exit 1
fi

SELECTED_ZIP="${BACKUP_FILES[$((SELECTION-1))]}"
echo "Selected backup: $(basename "${SELECTED_ZIP}")"

# Confirm restore
read -p "Warning: This will overwrite your current configuration at ${CONFIG_DIR}. Proceed? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Restore cancelled."
  exit 0
fi

# 1. Stop Prowlarr service if running
if docker service inspect "${SERVICE_NAME}" >/dev/null 2>&1; then
  echo "Scaling down ${SERVICE_NAME} to 0 replicas..."
  docker service scale "${SERVICE_NAME}=0"
  
  echo "Waiting for service to stop..."
  while [ "$(docker service ps -q -f "desired-state=running" "${SERVICE_NAME}" | wc -l)" -gt 0 ]; do
    sleep 1
  done
fi

# 2. Backup existing config to .old just in case
if [ -d "${CONFIG_DIR}" ]; then
  OLD_BACKUP_DIR="${CONFIG_DIR}_backup_$(date +%Y%m%d_%H%M%S).old"
  echo "Backing up current config directory to ${OLD_BACKUP_DIR}..."
  sudo mv "${CONFIG_DIR}" "${OLD_BACKUP_DIR}"
fi

# 3. Create fresh directory
echo "Creating fresh config directory at ${CONFIG_DIR}..."
sudo mkdir -p "${CONFIG_DIR}"

# 4. Extract backup zip using a temporary container to guarantee availability of 'unzip'
echo "Extracting backup to ${CONFIG_DIR}..."
docker run --rm \
  -v "${CONFIG_DIR}:/target" \
  -v "$(dirname "${SELECTED_ZIP}"):/backup_source" \
  alpine sh -c "apk add --no-cache unzip && unzip /backup_source/$(basename "${SELECTED_ZIP}") -d /target"

# 5. Fix permissions (1000:1000)
echo "Fixing permissions..."
sudo chown -R 1000:1000 "${CONFIG_DIR}"

# 6. Scale service back up if it was running
if docker service inspect "${SERVICE_NAME}" >/dev/null 2>&1; then
  echo "Scaling up ${SERVICE_NAME} back to 1 replica..."
  docker service scale "${SERVICE_NAME}=1"
fi

echo "Prowlarr restore completed successfully!"
