#!/bin/sh
# Seerr Jellyfin IaC — bypass the Seerr API entirely.
#
# Seerr normalizes settings.json on startup. When it sees a Jellyfin config
# without serverId/name populated (i.e. no validated connection), it resets
# port and useSsl to defaults. The serverId/name fields can only be set through
# Seerr's POST /api/v1/settings/jellyfin endpoint, which calls Jellyfin's
# /System/Info — and Jellyfin returns 403 for the API key for unknown reasons.
#
# This script sidesteps the problem: query Jellyfin's unauthenticated
# /System/Info/Public, extract the real serverId and ServerName, write them
# into settings.json alongside the Jellyfin config. Seerr sees populated
# serverId + name + initialized=true and skips both the wizard AND the
# normalization reset. No API POST, no CSRF, no auth token dance.
#
# Pitfalls:
#   - settings.json must exist BEFORE Seerr starts (the pre-write phase).
#     If it doesn't exist, create it with main.apiKey so Seerr doesn't
#     generate a fresh one on startup (which would discard our changes).
#   - The Jellyfin health-check uses the unauthenticated /System/Info/Public
#     endpoint. If Jellyfin isn't reachable at all, the script loops.

JELLYFIN_HOST="${JELLYFIN_HOST:-jellyfin}"
JELLYFIN_PORT="${JELLYFIN_PORT:-8096}"

SETTINGS_FILE="/app/config/settings.json"

# --- Diagnostics ---
if ! command -v jq > /dev/null 2>&1; then
    echo "[seerr-config] ERROR: jq is not available — Dockerfile apk add likely cached"
    echo "[seerr-config] Launching Seerr without Jellyfin config..."
    exec npm start
fi

echo "[seerr-config] Waiting for Jellyfin (${JELLYFIN_HOST}:${JELLYFIN_PORT})..."

# Wait for Jellyfin to be reachable — unauthenticated endpoint, always works
while true; do
    INFO_JSON=$(curl -sf "http://${JELLYFIN_HOST}:${JELLYFIN_PORT}/System/Info/Public" 2>/dev/null)
    if [ -n "$INFO_JSON" ]; then
        echo "[seerr-config] Jellyfin reachable"
        break
    fi
    sleep 3
done

# Extract Jellyfin's real serverId and server name
# /System/Info/Public returns lowercase keys: "id", "serverName"
JELLYFIN_ID=$(echo "$INFO_JSON" | jq -r '.id // empty' 2>/dev/null)
JELLYFIN_NAME=$(echo "$INFO_JSON" | jq -r '.serverName // empty' 2>/dev/null)

if [ -z "$JELLYFIN_ID" ] || [ -z "$JELLYFIN_NAME" ]; then
    echo "[seerr-config] WARNING: Could not extract Jellyfin Id/ServerName from /System/Info/Public"
    echo "[seerr-config] Response: $INFO_JSON"
    echo "[seerr-config] Proceeding without serverId/name — Seerr may normalize port/useSsl"
fi

# Write settings.json with all Jellyfin fields populated + initialized flag
echo "[seerr-config] Writing Seerr config (serverId=$JELLYFIN_ID)..."
if [ -f "$SETTINGS_FILE" ]; then
    # Patch existing settings.json
    if ! jq \
        --arg host "$JELLYFIN_HOST" \
        --arg port "$JELLYFIN_PORT" \
        --arg apiKey "${JELLYFIN_API_KEY:-}" \
        --arg serverId "$JELLYFIN_ID" \
        --arg name "$JELLYFIN_NAME" \
        '.jellyfin.hostname = $host
         | .jellyfin.ip = $host
         | .jellyfin.port = ($port | tonumber)
         | .jellyfin.useSsl = false
         | .jellyfin.apiKey = $apiKey
         | .jellyfin.serverId = $serverId
         | .jellyfin.name = $name
         | .public.initialized = true' \
        "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" 2>/dev/null; then
        mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        echo "[seerr-config] Settings written (host=${JELLYFIN_HOST}, port=${JELLYFIN_PORT}, serverId=${JELLYFIN_ID})"
    else
        echo "[seerr-config] WARNING: jq merge failed"
        rm -f "$SETTINGS_FILE.tmp"
    fi
else
    # First run — create a minimal settings.json so Seerr doesn't
    # discard our Jellyfin config on startup
    echo "[seerr-config] First run — creating settings.json"
    cat > "$SETTINGS_FILE" << ENODOC
{
  "jellyfin": {
    "hostname": "${JELLYFIN_HOST}",
    "ip": "${JELLYFIN_HOST}",
    "port": ${JELLYFIN_PORT},
    "useSsl": false,
    "apiKey": "${JELLYFIN_API_KEY:-}",
    "serverId": "${JELLYFIN_ID}",
    "name": "${JELLYFIN_NAME}",
    "urlBase": "",
    "libraries": []
  },
  "main": {
    "apiKey": "$(cat /proc/sys/kernel/random/uuid)",
    "trustProxy": false
  },
  "public": {
    "initialized": true
  }
}
ENODOC
fi

echo "[seerr-config] Done — launching Seerr"
exec npm start
