# Apollo Core

Media management and playback stack. Part of the unified Apollo media system. Deployed as a Docker Swarm stack across muspelheim (storage) and gaia (manager) nodes.

## Services

| Service | Hostname | Port | Purpose |
|:---|:---|:---|:---|
| Jellyfin | `jellyfin` | 8096 | Media server with LDAP auth |
| Jellystat | `jellystat` | 3000 | Jellyfin analytics and statistics |
| Jellystat DB | `jellystat-db` | 5432 | PostgreSQL backend for Jellystat |
| Sonarr | `sonarr` | 8989 | TV series management |
| Radarr | `radarr` | 7878 | Movie management |
| Lidarr | `lidarr` | 8686 | Music management |
| Bazarr | `bazarr` | 6767 | Automated subtitle management |
| Prowlarr | `prowlarr` | 9696 | Indexer proxy for all Arrs |
| Recyclarr | `recyclarr` | — | TRaSH Guide sync for Radarr/Sonarr quality profiles |
| Seerr | `seerr` | 5055 | Unified media requests (merged Overseerr + Jellyseerr) |
| Audiobookshelf | `audiobookshelf` | 80 | Audiobook server with mobile sync |
| MeTube | `metube` | 8081 | YouTube downloader (cookie-auth) |

## Documentation

Full stack documentation lives in the vault: `Areas/90-Infrastructure/Apollo/Apollo Stack.md`

Includes architecture diagrams, service communication flows, troubleshooting guides, deployment procedures, backup architecture, and historical timeline. The Historical/ folder in that area has all archived task logs and project specs.

## Deploy

```bash
./scripts/deploy.sh apollo-core
```

Requires: muspelheim and manager nodes active, `aether-net` overlay network, host prep scripts run.

## Related

- `apollo-supply` — VPN + download clients (companion stack)
- `Areas/90-Infrastructure/Apollo/` — detailed reference docs
