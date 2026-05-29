FROM ghcr.io/seerr-team/seerr:latest

# Add jq for settings.json manipulation
USER root
RUN apk add --no-cache curl jq
COPY seerr/root/app/configure-jellyfin.sh /app/configure-jellyfin.sh
RUN chmod +x /app/configure-jellyfin.sh
USER node

# Start Seerr, wait for API, configure Jellyfin via API endpoint
CMD ["/bin/sh", "-c", "/app/configure-jellyfin.sh"]
