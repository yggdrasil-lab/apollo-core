#!/bin/bash
# Expand LDAP-Auth.xml from template using environment variables.
# Runs before Jellyfin starts via s6-overlay custom-cont-init.
set -euo pipefail

TEMPLATE="/app/ldapauth.xml.template"
OUTPUT="/config/data/plugins/configurations/LDAP-Auth.xml"

# If template doesn't exist (should never happen), skip
[ -f "$TEMPLATE" ] || exit 0

# Set defaults for optional vars
export LDAP_SERVER="${LDAP_SERVER:-authentik-ldap}"
export LDAP_PORT="${LDAP_PORT:-3389}"
export LDAP_BIND_USER="${LDAP_BIND_USER:-akadmin}"
export LLDAP_JELLYFIN_USERS_GROUP="${LLDAP_JELLYFIN_USERS_GROUP:-JellyfinUsers}"
export LLDAP_JELLYFIN_ADMINS_GROUP="${LLDAP_JELLYFIN_ADMINS_GROUP:-JellyfinAdministrator}"

# Format full bind DN if a simple username was provided
if [[ "$LDAP_BIND_USER" == *"="* ]]; then
  FULL_BIND_DN="$LDAP_BIND_USER"
else
  FULL_BIND_DN="cn=${LDAP_BIND_USER},ou=users,${LLDAP_LDAP_BASE_DN}"
fi

echo "[ldap-config] Expanding $TEMPLATE -> $OUTPUT"
echo "[ldap-config] LDAP Server: ${LDAP_SERVER}:${LDAP_PORT}"
echo "[ldap-config] LDAP Bind User: ${FULL_BIND_DN}"

mkdir -p "$(dirname "$OUTPUT")"

# Expand template using sed (no python3 dependency)
cp "$TEMPLATE" "$OUTPUT"
sed -i "s#\$LDAP_SERVER#$LDAP_SERVER#g" "$OUTPUT"
sed -i "s#\$LDAP_PORT#$LDAP_PORT#g" "$OUTPUT"
sed -i "s#\$LDAP_BIND_USER#$FULL_BIND_DN#g" "$OUTPUT"
sed -i "s#\$LLDAP_LDAP_BASE_DN#$LLDAP_LDAP_BASE_DN#g" "$OUTPUT"
sed -i "s#\$LLDAP_LDAP_USER_PASS#$LLDAP_LDAP_USER_PASS#g" "$OUTPUT"
sed -i "s#\$LLDAP_JELLYFIN_USERS_GROUP#$LLDAP_JELLYFIN_USERS_GROUP#g" "$OUTPUT"
sed -i "s#\$LLDAP_JELLYFIN_ADMINS_GROUP#$LLDAP_JELLYFIN_ADMINS_GROUP#g" "$OUTPUT"

echo "[ldap-config] Done"
