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

python3 -c "
import os
with open('$TEMPLATE') as f:
    expanded = os.path.expandvars(f.read())
with open('$OUTPUT', 'w') as f:
    f.write(expanded)
"

echo "[ldap-config] Done"
