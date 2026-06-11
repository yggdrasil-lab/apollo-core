#!/bin/sh
# Recyclarr entrypoint wrapper — generates recyclarr.yml from env vars before starting.
# Placeholders __RADARR_API_KEY__ and __SONARR_API_KEY__ are replaced at container start.
#
# The TRaSH Guide quality profiles (identified by trash_id) already include
# custom format scores for blocking CAM/TS/TC releases. No extra config needed.

CONFIG_FILE="/config/recyclarr.yml"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Recyclarr: generating config from template..."

    cat > "$CONFIG_FILE" << 'YAMLEOF'
# Recyclarr configuration — auto-generated on first start.
# Managed via IaC (apollo-core). Do not edit manually on the host.

radarr:
  movies:
    base_url: http://radarr:7878
    api_key: __RADARR_API_KEY__

    quality_definition:
      type: movie

    quality_profiles:
      - trash_id: d1d67249d3890e49bc12e275d989a7e9   # HD Bluray + WEB
        reset_unmatched_scores:
          enabled: true

    delete_old_custom_formats: true

sonarr:
  tv:
    base_url: http://sonarr:8989
    api_key: __SONARR_API_KEY__

    quality_definition:
      type: series

    quality_profiles:
      - trash_id: b4e3a9e82b7c4f5d8a1e2b3c4d5e6f7a   # WEB-1080p
        reset_unmatched_scores:
          enabled: true

    delete_old_custom_formats: true
YAMLEOF

    # Substitute API keys (using # as delimiter to handle special chars in keys)
    sed -i \
        -e "s#__RADARR_API_KEY__#${RADARR_API_KEY}#g" \
        -e "s#__SONARR_API_KEY__#${SONARR_API_KEY}#g" \
        "$CONFIG_FILE"

    echo "Recyclarr: config generated at $CONFIG_FILE"
fi

exec recyclarr "$@"
