# Pinned to the 12.1 build (upgraded from 10.11.11). :latest also resolves to 12.1,
# but staying pinned keeps deploys from moving the version.
# Rollback before the migration runs: revert to 10.11.11ubu2604-ls47.
FROM lscr.io/linuxserver/jellyfin:12.1ubu2604-ls50

# Plugin deduplication — keep only the latest version of each plugin
COPY jellyfin/root/custom-cont-init.d/30-plugin-cleanup.sh /custom-cont-init.d/30-plugin-cleanup.sh
RUN chmod +x /custom-cont-init.d/30-plugin-cleanup.sh

# LDAP config expansion from env vars at container start
COPY jellyfin/root/custom-cont-init.d/40-ldap-config.sh /custom-cont-init.d/40-ldap-config.sh
COPY jellyfin/root/app/ldapauth.xml.template /app/ldapauth.xml.template
RUN chmod +x /custom-cont-init.d/40-ldap-config.sh
