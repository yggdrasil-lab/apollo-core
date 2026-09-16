# Pinned to the 10.11.11 build. :latest resolves to 12.1, so an unpinned rebuild
# would jump versions. Moving to 12.1 is a separate, planned change.
FROM lscr.io/linuxserver/jellyfin:10.11.11ubu2604-ls47

# Plugin deduplication — keep only the latest version of each plugin
COPY jellyfin/root/custom-cont-init.d/30-plugin-cleanup.sh /custom-cont-init.d/30-plugin-cleanup.sh
RUN chmod +x /custom-cont-init.d/30-plugin-cleanup.sh

# LDAP config expansion from env vars at container start
COPY jellyfin/root/custom-cont-init.d/40-ldap-config.sh /custom-cont-init.d/40-ldap-config.sh
COPY jellyfin/root/app/ldapauth.xml.template /app/ldapauth.xml.template
RUN chmod +x /custom-cont-init.d/40-ldap-config.sh
