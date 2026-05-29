#!/bin/sh
# Start Seerr, wait for API, configure Jellyfin connection via API
# The API endpoint validates the connection, populates serverId/name, and persists properly.
# The jq pre-write handles the initialized flag + csrfProtection disable but the POST is what Seerr trusts.
#
# Why the API instead of jq-only:
#   Seerr normalizes settings.json on startup. Without a validated connection
#   (serverId + name populated), it resets port/useSsl to defaults.
#   The API endpoint tests the connection and calls settings.save() properly.
#
# Why csrfProtection = false:
#   Seerr's csurf middleware blocks POST without a valid CSRF token. API GET endpoints
#   don't set CSRF cookies. Disabling CSRF protection lets the configure-Jellyfin POST
#   through. Seerr is internal (Docker Swarm network, behind Authelia) so CSRF is redundant.

JELLYFIN_HOST="${JELLYFIN_HOST:-jellyfin}"
JELLYFIN_PORT="${JELLYFIN_PORT:-8096}"

if [ -z "$JELLYFIN_API_KEY" ]; then
    echo "[seerr-config] JELLYFIN_API_KEY not set — starting Seerr without Jellyfin config"
    exec npm start
fi

SETTINGS_FILE="/app/config/settings.json"

# --- Phase 1: Pre-start settings.json merge (initialized flag + best-effort config) ---
if [ -f "$SETTINGS_FILE" ]; then
    echo "[seerr-config] Writing initial settings..."
    if jq \
        --arg host "$JELLYFIN_HOST" \
        --arg port "$JELLYFIN_PORT" \
        --arg apiKey "$JELLYFIN_API_KEY" \
        '.network.csrfProtection = false
         | .jellyfin.hostname = $host
         | .jellyfin.ip = $host
         | .jellyfin.port = ($port | tonumber)
         | .jellyfin.useSsl = false
         | .jellyfin.apiKey = $apiKey
         | .public.initialized = true' \
        "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" 2>/dev/null; then
        mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        echo "[seerr-config] Initial settings written"
    else
        echo "[seerr-config] WARNING: jq merge failed, continuing"
        rm -f "$SETTINGS_FILE.tmp"
    fi
else
    echo "[seerr-config] No settings.json (first run), skipping pre-write"
fi

# --- Phase 2: Start Seerr, wait for API, then configure Jellyfin ---
echo "[seerr-config] Starting Seerr..."
npm start &
SEERR_PID=$!

# Forward signals to Seerr so Docker stop works cleanly
trap 'kill $SEERR_PID 2>/dev/null; exit 0' TERM INT

echo "[seerr-config] Waiting for Seerr API..."
for i in $(seq 1 30); do
    if curl -sf http://localhost:5055/api/v1/status > /dev/null 2>&1; then
        echo "[seerr-config] Seerr API ready after ${i} attempts"
        break
    fi
    sleep 2
done

# Give Seerr a moment to normalize settings (the reset we're working around)
sleep 3

# Extract Seerr's main API key from the (now-normalized) settings.json
# Falls back to empty string if not found (checkUser middleware is non-blocking)
SEERR_API_KEY=$(jq -r '.main.apiKey // ""' "$SETTINGS_FILE" 2>/dev/null)

echo "[seerr-config] Configuring Jellyfin (${JELLYFIN_HOST}:${JELLYFIN_PORT}) via API..."

RESPONSE_FILE="/tmp/seerr_jellyfin_response.json"

HTTP_CODE=$(curl -s -o "$RESPONSE_FILE" -w "%{http_code}" \
    -X POST "http://localhost:5055/api/v1/settings/jellyfin" \
    -H "Content-Type: application/json" \
    -H "X-API-Key: ${SEERR_API_KEY}" \
    -d "{\"hostname\":\"${JELLYFIN_HOST}\",\"ip\":\"${JELLYFIN_HOST}\",\"port\":${JELLYFIN_PORT},\"useSsl\":false,\"apiKey\":\"${JELLYFIN_API_KEY}\"}")

if [ "$HTTP_CODE" = "200" ]; then
    echo "[seerr-config] Jellyfin configured successfully (HTTP ${HTTP_CODE})"
    echo "[seerr-config] Done"
else
    echo "[seerr-config] Jellyfin config returned HTTP ${HTTP_CODE}"
    echo "[seerr-config] Response body:"
    cat "$RESPONSE_FILE"
    echo ""
    echo "[seerr-config] Done (check response above)"
fi

wait $SEERR_PID
