# Apollo Core

> I am **Apollo**, the God of Music, Light, and Art. I am the **Media Manager** of the Yggdrasil ecosystem. My domain is the curation, organization, and delivery of inspiration to the digital realm.

## Mission

I exist to bring order to chaos and melody to silence. My purpose is to maintain the **Golden Library**—your collection of films, series, harmonies, and tales. I ensure that when you seek to be entertained or inspired, the performance begins without delay.

## Core Philosophy

*   **Harmony (Integration)**: Every instrument (Service) must play in tune. Sonarr, Radarr, and Plex must listen to one another to create a seamless symphony.
*   **The Golden Light (Quality)**: I do not accept the grainy or the distorted. We seek only the highest fidelity (4K, FLAC) to honor the art.
*   **Immortality (Persistence)**: A story forgotten is a story lost. I work with **Charon** to ensure the library is preserved against the ravages of time.

---

---

## Architecture & Connectivity

The system operates as a distributed stack across the swarm, utilizing the overlay network `aether-net` for internal communication.

### Service Overview

| Service | Hostname (Internal) | Port | Purpose | Connection Type |
| :--- | :--- | :--- | :--- | :--- |
| **Plex** | `plex` | 32400 | Media Server | Filesystem (Read) |
| **Jellyfin** | `jellyfin` | 8096 | Media Server | Filesystem (Read) |
| **Sonarr** | `sonarr` | 8989 | TV Management | Filesystem (Write) + API |
| **Radarr** | `radarr` | 7878 | Movie Management | Filesystem (Write) + API |
| **Lidarr** | `lidarr` | 8686 | Music Management | Filesystem (Write) + API |
| **Prowlarr** | `prowlarr` | 9696 | Indexer Proxy | API Only |
| **Overseerr** | `overseerr` | 5055 | Requests UI | API Only |
| **Tautulli** | `tautulli` | 8181 | Plex Statistics | API Only |

### Internal Communication (API & Network)

*   **Prowlarr ↔ Arrs**: Prowlarr pushes indexer configurations to Sonarr/Radarr/Lidarr via API.
*   **Overseerr → Arrs**: Overseerr sends approval commands to Sonarr/Radarr to add shows/movies via API.
*   **Arrs → Muspelheim**: The *Arr* services execute file operations on the host storage (`/mnt/storage/media`) to organize content.

## Filesystem Access (Bind Mounts)

Physical storage is mounted from the `muspelheim` host into the containers.

*   **Media Access (`/media`)**
    *   **Path**: `/mnt/storage/media` (Host) → `/media` (Container).
    *   **Services**: `plex`, `jellyfin`, `sonarr`, `radarr`.
    *   **Flow**:
        1.  **Sonarr/Radarr** see completed downloads and move them to `/media/TV` or `/media/Movies`.
        2.  **Plex/Jellyfin** scan `/media` to play content.

*   **Configuration (`/config`)**
    *   **Path**: `/opt/apollo-core/<service_name>` (Host) → `/config` (Container).
    *   **Function**: Persistent storage for application databases and settings.

*   **App Backups (`/config/backups`)**
    *   **Path**: `/mnt/storage/backups/apollo/<service>` (Host) → `/config/Backups` (Container).
    *   **Services**: `sonarr`, `radarr`, `lidarr`, `prowlarr`.
    *   **Function**: Landing zone for internal application backups (zips). These are swept up by **Charon** (The Ferryman) and shipped to the cloud.

---

## Deployment

Deployments are handled via the unified `ops-scripts` workflow on the `gaia` manager node.

```bash
# Standard deployment
./scripts/deploy.sh apollo-core

# Prune/Clean deployment
./scripts/deploy.sh apollo-core --prune
```

### Requirements
- **Node**: `muspelheim` and `manager` must be active in the Swarm.
- **Network**: `aether-net` must exist (see `Forge/yggdrasil-os`).
- **Host Preparation**:
  Copy `setup_host.sh` to the host (Muspelheim) and run it:
  ```bash
  chmod +x setup_host.sh
  ./setup_host.sh
  ```

---

## Configuration & Onboarding

### 1. Prowlarr (Indexers)
*   **Initial Setup**: Create an admin account.
*   **Add Indexers**: Go to "Indexers" > "Add Indexer" > Search.
*   **Connect Clients**: Go to "Settings" > "Apps" > Add Sonarr, Radarr, and Lidarr.
    *   *Prowlarr Host*: `http://prowlarr:9696`
    *   *API Key*: Get from the respective app's "Settings" > "General".

### 2. Sonarr, Radarr, Lidarr (Content Managers)
*   **Media Management**: Enable "Rename Files". Add Root Folders (`/media/TV`, `/media/Movies`, `/media/Music`).
*   **Indexers**: These will appear automatically once Prowlarr is configured.
*   **Download Clients**: Connect to your external downloader (e.g., `glacier-torrent`).

### 3. Plex & Jellyfin (Media Servers)
*   **Claim Server**: Set `PLEX_CLAIM` or use SSH tunnel for initial Plex setup.
*   **Libraries**: Point to `/media/Movies`, `/media/TV`, `/media/Music`.
*   **Remote Access**: Disable internal remote access; let Traefik handle the routing.

### 4. Backup Configuration (Critical)
To ensure **Charon** can ship your backups, you must configure the internal backup location for **Sonarr**, **Radarr**, **Lidarr**, and **Prowlarr**.

1.  **Navigate**: Go to **Settings** > **General** > **Backups**.
2.  **Interval**: Set to **Scheduled** (e.g., every 7 days).
3.  **Retention**: Set to desired window (e.g., 28 days).
4.  **Location**: Change the default path to: `/config/Backups`.
    *   *Note*: This maps to `/mnt/storage/backups/apollo/<service>` on the host.
5.  **Test**: Click **Save**, then trigger a manual backup to verify.

---

## Sharing & Mobile Apps

### 🎥 Plex
*   **How to Share**: Settings > Manage Library Access > Grant Access (by email).
*   **Apps**: Plex (iOS/Android/TV).

### 📥 Overseerr
*   **How to Share**: Users log in with their **Plex Account**.
*   **Apps**: Add the website to your Home Screen (PWA).

> **Note from Apollo:** I do not curate what I do not see. Ensure your requests in Overseerr are precise, for I shall deliver them exactly as asked.

