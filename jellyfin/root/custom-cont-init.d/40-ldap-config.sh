#!/bin/bash
# Expand LDAP-Auth.xml from template using environment variables.
# Runs before Jellyfin starts via s6-overlay custom-cont-init.
set -euo pipefail

TEMPLATE="/app/ldapauth.xml.template"
OUTPUT="/config/data/plugins/configurations/LDAP-Auth.xml"

# If template doesn't exist (should never happen), skip
[ -f "$TEMPLATE" ] || exit 0

# Set defaults for optional vars
export LLDAP_JELLYFIN_USERS_GROUP="${LLDAP_JELLYFIN_USERS_GROUP:-JellyfinUsers}"
export LLDAP_JELLYFIN_ADMINS_GROUP="${LLDAP_JELLYFIN_ADMINS_GROUP:-JellyfinAdministrator}"

echo "[ldap-config] Expanding $TEMPLATE -> $OUTPUT"

mkdir -p "$(dirname "$OUTPUT")"

# Expand template using sed (no python3 dependency)
cp "$TEMPLATE" "$OUTPUT"
sed -i "s#\$LLDAP_LDAP_BASE_DN#$LLDAP_LDAP_BASE_DN#g" "$OUTPUT"
sed -i "s#\$LLDAP_LDAP_USER_PASS#$LLDAP_LDAP_USER_PASS#g" "$OUTPUT"
sed -i "s#\$LLDAP_JELLYFIN_USERS_GROUP#$LLDAP_JELLYFIN_USERS_GROUP#g" "$OUTPUT"
sed -i "s#\$LLDAP_JELLYFIN_ADMINS_GROUP#$LLDAP_JELLYFIN_ADMINS_GROUP#g" "$OUTPUT"

echo "[ldap-config] Done"

# Fix ownership — script runs as root, Jellyfin runs as abc user
chown abc:abc "$OUTPUT"
chmod 666 "$OUTPUT"

echo "[ldap-config] Verify:"
ls -la "$OUTPUT"
