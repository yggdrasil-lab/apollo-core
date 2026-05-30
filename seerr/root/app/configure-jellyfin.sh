#!/bin/sh
# Configure Seerr's Jellyfin connection on container startup.
#
# Why this approach:
#   Seerr normalizes settings.json on startup. If serverId is empty,
#   it resets port→80 and useSsl→null (defaults). We extract the real
#   Jellyfin serverId from /System/Info/Public BEFORE Seerr starts,
#   populate it in settings.json, and Seerr trusts the config.
#
# Why jq // fallthrough:
#   Jellyfin 10.11.10 alternates between lowercase and PascalCase keys
#   across restarts (id/Id, serverName/ServerName). jq's // operator
#   falls through to the next expression when the first returns null.
#
# Why /System/Info/Public (not /System/Info):
#   /System/Info requires authentication and returns 403 for some API
#   keys in Jellyfin 10.11.10. /System/Info/Public is unauthenticated
#   and returns the same Id and ServerName fields.
#
# Why no API POST:
#   Seerr's POST /api/v1/settings/jellyfin calls getSystemInfo() to
#   validate the connection. Jellyfin 10.11.10 returns 403 for this
#   call even with a valid admin API key. Skipping the validation and
#   writing serverId directly is simpler and works reliably.
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
# /System/Info/Public returns either lowercase or PascalCase keys — handle both
JELLYFIN_ID=$(echo "$INFO_JSON" | jq -r '.Id // .id // empty' 2>/dev/null)
JELLYFIN_NAME=$(echo "$INFO_JSON" | jq -r '.ServerName // .serverName // empty' 2>/dev/null)

if [ -z "$JELLYFIN_ID" ] || [ -z "$JELLYFIN_NAME" ]; then
    echo "[seerr-config] WARNING: Could not extract Jellyfin Id/ServerName from /System/Info/Public"
    echo "[seerr-config] Response: $INFO_JSON"
    echo "[seerr-config] Proceeding without serverId/name — Seerr may normalize port/useSsl"
fi

# Write settings.json with all Jellyfin fields populated + initialized flag
echo "[seerr-config] Writing Seerr config (serverId=$JELLYFIN_ID)..."

if [ -f "$SETTINGS_FILE" ]; then
    # Patch existing settings.json
    JQ_ERR=$(mktemp)
    if jq \
        --arg host "$JELLYFIN_HOST" \
        --arg port "$JELLYFIN_PORT" \
        --arg apiKey "${JELLYFIN_API_KEY:-}" \
        --arg serverId "$JELLYFIN_ID" \
        --arg name "$JELLYFIN_NAME" \
        '.network.csrfProtection = false
         | .jellyfin.hostname = $host
         | .jellyfin.ip = $host
         | .jellyfin.port = ($port | tonumber)
         | .jellyfin.useSsl = false
         | .jellyfin.apiKey = $apiKey
         | .jellyfin.serverId = $serverId
         | .jellyfin.name = $name
         | .public.initialized = true' \
        "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" 2>"$JQ_ERR"; then
        mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        echo "[seerr-config] Settings written (host=${JELLYFIN_HOST}, port=${JELLYFIN_PORT}, serverId=${JELLYFIN_ID})"
        rm -f "$JQ_ERR"
    else
        JQ_EXIT=$?
        echo "[seerr-config] WARNING: jq merge failed (exit=$JQ_EXIT)"
        echo "[seerr-config] jq stderr: $(cat "$JQ_ERR")"
        rm -f "$SETTINGS_FILE.tmp" "$JQ_ERR"
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
