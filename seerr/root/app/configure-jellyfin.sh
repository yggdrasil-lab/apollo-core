#!/bin/sh
# Configure Seerr's Jellyfin connection on container startup.
#
# Two-pass approach:
#   Pass 1: Write settings.json → start Seerr → it normalizes port/useSsl
#   Post-start: jq fixes port/useSsl → restart Seerr
#   Pass 2: Seerr sees complete config → accepts it
#   Future restarts: fast-path skips everything → instant launch
#
# Why two passes:
#   Seerr normalizes settings.json on startup. Even with a populated
#   serverId, port reverts to 80 and useSsl to null — Seerr only trusts
#   API-validated values for these two fields. Writing serverId from
#   Jellyfin's /System/Info/Public populates the untrusted fields, then
#   we fix port/useSsl post-normalization and restart. On pass 2, Seerr
#   sees all fields populated and accepts them.
#
# Why /System/Info/Public (not /System/Info):
#   /System/Info requires authentication and returns 403 for some API
#   keys in Jellyfin 10.11.10. /System/Info/Public is unauthenticated
#   and returns the same Id and ServerName fields.
#
# Why jq // fallthrough:
#   Jellyfin 10.11.10 alternates between lowercase and PascalCase keys
#   across restarts (id/Id, serverName/ServerName). jq's // operator
#   falls through to the next expression when the first returns null.

JELLYFIN_HOST="${JELLYFIN_HOST:-jellyfin}"
JELLYFIN_PORT="${JELLYFIN_PORT:-8096}"

SETTINGS_FILE="/app/config/settings.json"

# --- Diagnostics ---
if ! command -v jq > /dev/null 2>&1; then
    echo "[seerr-config] ERROR: jq is not available — Dockerfile apk add likely cached"
    echo "[seerr-config] Launching Seerr without Jellyfin config..."
    exec npm start
fi

# --- Fast path: config already valid ---
if [ -f "$SETTINGS_FILE" ]; then
    FAST_PORT=$(jq -r '.jellyfin.port // 0' "$SETTINGS_FILE" 2>/dev/null)
    FAST_SID=$(jq -r '.jellyfin.serverId // ""' "$SETTINGS_FILE" 2>/dev/null)
    FAST_SSL=$(jq -r '.jellyfin.useSsl // "null"' "$SETTINGS_FILE" 2>/dev/null)

    if [ "$FAST_PORT" = "$JELLYFIN_PORT" ] && [ -n "$FAST_SID" ] && [ "$FAST_SSL" = "false" ]; then
        echo "[seerr-config] Config valid (port=$FAST_PORT, serverId=$FAST_SID) — skip"
        exec npm start
    fi
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
    jq \
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
        "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"

    if [ $? -eq 0 ]; then
        mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        echo "[seerr-config] Settings written (host=${JELLYFIN_HOST}, port=${JELLYFIN_PORT}, serverId=${JELLYFIN_ID})"
    else
        echo "[seerr-config] WARNING: jq merge failed (exit=$?)"
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

# ─────────────────────────────────────────────────────────
# Two-pass startup
# ─────────────────────────────────────────────────────────

echo "[seerr-config] Pass 1 — starting Seerr..."
npm start &
SEERR_PID=$!

# Wait for Seerr API to be ready
echo "[seerr-config] Waiting for Seerr API..."
READY=0
for i in $(seq 1 30); do
    if curl -sf "http://localhost:5055/api/v1/status" > /dev/null 2>&1; then
        echo "[seerr-config] Seerr API ready after ${i} attempts"
        READY=1
        break
    fi
    sleep 2
done

if [ "$READY" = "0" ]; then
    echo "[seerr-config] WARNING: Seerr API did not become ready — keeping existing process"
    wait $SEERR_PID
    exit 0
fi

# Check if Seerr normalized port/useSsl back to defaults
PORT=$(jq -r '.jellyfin.port // 0' "$SETTINGS_FILE" 2>/dev/null)
SSL=$(jq -r '.jellyfin.useSsl // "null"' "$SETTINGS_FILE" 2>/dev/null)

if [ "$PORT" = "$JELLYFIN_PORT" ] && [ "$SSL" = "false" ]; then
    echo "[seerr-config] Config survived normalization (port=$PORT) — keeping Seerr"
    wait $SEERR_PID
else
    echo "[seerr-config] Seerr normalized config (port=$PORT, useSsl=$SSL) — fixing..."

    # Fix port and useSsl in-place (serverId/apiKey already survived normalization)
    jq \
        --arg port "$JELLYFIN_PORT" \
        '.jellyfin.port = ($port | tonumber) | .jellyfin.useSsl = false' \
        "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && \
        mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"

    echo "[seerr-config] Config fixed — killing old Seerr (PID=$SEERR_PID)..."
    kill $SEERR_PID 2>/dev/null || true

    # Wait for old Seerr to die
    for i in $(seq 1 15); do
        if kill -0 $SEERR_PID 2>/dev/null; then
            sleep 1
        else
            echo "[seerr-config] Old Seerr stopped after ${i}s"
            break
        fi
    done

    # If still alive, force kill
    if kill -0 $SEERR_PID 2>/dev/null; then
        echo "[seerr-config] Force killing Seerr..."
        kill -9 $SEERR_PID 2>/dev/null || true
        sleep 1
    fi

    echo "[seerr-config] Pass 2 — launching Seerr with fixed config"
    exec npm start
fi
