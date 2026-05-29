FROM lscr.io/linuxserver/jellyfin:latest

# Plugin deduplication — keep only the latest version of each plugin
COPY jellyfin/root/custom-cont-init.d/30-plugin-cleanup.sh /custom-cont-init.d/30-plugin-cleanup.sh
RUN chmod +x /custom-cont-init.d/30-plugin-cleanup.sh

# LDAP config expansion from env vars at container start
COPY jellyfin/root/custom-cont-init.d/40-ldap-config.sh /custom-cont-init.d/40-ldap-config.sh
COPY jellyfin/root/app/ldapauth.xml.template /app/ldapauth.xml.template
RUN chmod +x /custom-cont-init.d/40-ldap-config.sh
