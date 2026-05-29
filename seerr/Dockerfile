FROM ghcr.io/seerr-team/seerr:latest

# Add jq for settings.json manipulation
USER root
RUN apk add --no-cache jq
COPY seerr/root/app/configure-jellyfin.sh /app/configure-jellyfin.sh
RUN chmod +x /app/configure-jellyfin.sh
USER node

# Merge Jellyfin config into settings.json, then start Seerr
CMD ["/bin/sh", "-c", "/app/configure-jellyfin.sh && exec npm start"]
