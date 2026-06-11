FROM ghcr.io/recyclarr/recyclarr:8

# Wrapper entrypoint: generates recyclarr.yml from env vars on first start,
# then delegates to the original recyclarr binary.
COPY recyclarr/entrypoint.sh /recyclarr-entrypoint.sh
RUN chmod +x /recyclarr-entrypoint.sh
ENTRYPOINT ["/recyclarr-entrypoint.sh"]
