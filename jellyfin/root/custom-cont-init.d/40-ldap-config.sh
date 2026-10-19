#!/bin/bash
# Expand LDAP-Auth.xml from template using environment variables.
# Runs before Jellyfin starts via s6-overlay custom-cont-init.
set -euo pipefail

TEMPLATE="/app/ldapauth.xml.template"
OUTPUT="/config/data/plugins/configurations/LDAP-Auth.xml"

# If template doesn't exist (should never happen), skip
[ -f "$TEMPLATE" ] || exit 0

# Validate all required variables fail loudly if not set or empty
for var in LDAP_SERVER LDAP_PORT LDAP_BIND_USER LDAP_BIND_PASSWORD LDAP_BASE_DN LDAP_JELLYFIN_USERS_GROUP LDAP_JELLYFIN_ADMINS_GROUP DOMAIN_NAME; do
  if [ -z "${!var:-}" ]; then
    echo "[ldap-config] ERROR: Required environment variable $var is unset or empty!" >&2
    exit 1
  fi
done

# Format full bind DN if a simple username was provided
if [[ "$LDAP_BIND_USER" == *"="* ]]; then
  FULL_BIND_DN="$LDAP_BIND_USER"
else
  FULL_BIND_DN="cn=${LDAP_BIND_USER},ou=users,${LDAP_BASE_DN}"
fi

PASSWORD_RESET_URL="https://id.${DOMAIN_NAME}/if/flow/default-recovery-flow/"

echo "[ldap-config] Expanding $TEMPLATE -> $OUTPUT"
echo "[ldap-config] LDAP Server: ${LDAP_SERVER}:${LDAP_PORT}"
echo "[ldap-config] LDAP Bind User: ${FULL_BIND_DN}"
echo "[ldap-config] Password Reset URL: ${PASSWORD_RESET_URL}"

mkdir -p "$(dirname "$OUTPUT")"

# Expand template using sed (no python3 dependency)
cp "$TEMPLATE" "$OUTPUT"
sed -i "s#\$LDAP_SERVER#$LDAP_SERVER#g" "$OUTPUT"
sed -i "s#\$LDAP_PORT#$LDAP_PORT#g" "$OUTPUT"
sed -i "s#\$LDAP_BIND_USER#$FULL_BIND_DN#g" "$OUTPUT"
sed -i "s#\$LDAP_BIND_PASSWORD#$LDAP_BIND_PASSWORD#g" "$OUTPUT"
sed -i "s#\$LDAP_BASE_DN#$LDAP_BASE_DN#g" "$OUTPUT"
sed -i "s#\$LDAP_JELLYFIN_USERS_GROUP#$LDAP_JELLYFIN_USERS_GROUP#g" "$OUTPUT"
sed -i "s#\$LDAP_JELLYFIN_ADMINS_GROUP#$LDAP_JELLYFIN_ADMINS_GROUP#g" "$OUTPUT"
sed -i "s#\$PASSWORD_RESET_URL#$PASSWORD_RESET_URL#g" "$OUTPUT"

echo "[ldap-config] Done"
