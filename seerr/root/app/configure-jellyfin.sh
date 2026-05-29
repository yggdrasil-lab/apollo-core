#!/bin/sh
# Merge Jellyfin connection into Seerr settings.json at startup
# This runs BEFORE Seerr starts, so the config is present from first boot

SETTINGS_FILE="/app/config/settings.json"
JELLYFIN_HOST="${JELLYFIN_HOST:-jellyfin}"
JELLYFIN_PORT="${JELLYFIN_PORT:-8096}"

if [ -z "$JELLYFIN_API_KEY" ]; then
    echo "[seerr-config] JELLYFIN_API_KEY not set, skipping"
    exit 0
fi

if [ ! -f "$SETTINGS_FILE" ]; then
    echo "[seerr-config] No settings.json (first run), skipping — configure via wizard"
    exit 0
fi

echo "[seerr-config] Merging Jellyfin (${JELLYFIN_HOST}:${JELLYFIN_PORT})"

jq \
  --arg host "$JELLYFIN_HOST" \
  --arg port "$JELLYFIN_PORT" \
  --arg apiKey "$JELLYFIN_API_KEY" \
  '.jellyfin.hostname = $host
   | .jellyfin.ip = $host
   | .jellyfin.port = ($port | tonumber)
   | .jellyfin.useSsl = false
   | .jellyfin.apiKey = $apiKey' \
  "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" \
  && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE" \
  && echo "[seerr-config] Done"

exit 0
