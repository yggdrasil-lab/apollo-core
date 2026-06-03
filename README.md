# Apollo Core

Media management and playback stack. Part of the unified Apollo media system. Deployed as a Docker Swarm stack across muspelheim (storage) and gaia (manager) nodes.

## Services

| Service | Hostname | Port | IP | Purpose |
|:---|:---|:---|:---|:---|
| Plex | `plex` | 32400 | 10.0.1.224 | Primary media server |
| Jellyfin | `jellyfin` | 8096 | 10.0.1.226 | Secondary media server with LDAP auth |
| Tautulli | `tautulli` | 8181 | 10.0.1.222 | Plex analytics and statistics |
| Sonarr | `sonarr` | 8989 | 10.0.1.228 | TV series management |
| Radarr | `radarr` | 7878 | 10.0.1.238 | Movie management |
| Lidarr | `lidarr` | 8686 | 10.0.1.234 | Music management |
| Bazarr | `bazarr` | 6767 | 10.0.1.236 | Automated subtitle management |
| Prowlarr | `prowlarr` | 9696 | 10.0.1.232 | Indexer proxy for all Arrs |
| Seerr | `seerr` | 5055 | 10.0.1.220 | Unified media requests (merged Overseerr + Jellyseerr) |
| LazyLibrarian | `lazylibrarian` | 5299 | 10.0.1.218 | Audiobook management (unstable — see pitfalls) |
| Audiobookshelf | `audiobookshelf` | 80 | 10.0.1.216 | Audiobook server with mobile sync |
| MeTube | `metube` | 8081 | 10.0.1.230 | YouTube downloader (cookie-auth) |

## Networks

All services attach to the `aether-net` overlay (10.0.1.0/24). Every service has a static IPv4 address assigned via `docker-compose.yml` to prevent IP pool exhaustion from restart churn. Current assignments match the services' dynamic leases at creation time — zero collision risk on redeploy.

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
