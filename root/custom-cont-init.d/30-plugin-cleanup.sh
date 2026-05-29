#!/bin/bash
# Deduplicate plugin directories — keep only the latest version of each plugin.
# Runs before Jellyfin starts via s6-overlay custom-cont-init.
set -euo pipefail

PLUGIN_DIR="/config/data/plugins"
[ -d "$PLUGIN_DIR" ] || exit 0

# Group directories by plugin name (strip version suffix like _22.0.0.0)
for plugin_name in $(ls -d "$PLUGIN_DIR"/*/ 2>/dev/null | sed 's|.*/||; s|_[0-9].*||' | sort -u); do
    versions=$(find "$PLUGIN_DIR" -maxdepth 1 -type d -name "${plugin_name}_*")
    count=$(echo "$versions" | wc -l)
    [ "$count" -le 1 ] && continue

    echo "[plugin-cleanup] Found $count versions of '$plugin_name' — keeping latest"
    latest=$(echo "$versions" | sort -Vr | head -1)

    echo "$versions" | while read -r dir; do
        [ "$dir" = "$latest" ] && continue
        echo "[plugin-cleanup] Removing $dir"
        rm -rf "$dir"
    done
done
