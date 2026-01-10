# Apollo Core

This repository contains the "Playback and Management" layer of the media stack.
- **Heavy Services** (Media/Storage): Deployed on the `muspelheim` worker node.
- **Lightweight Services** (Management/UI): Deployed on the `manager` node.

## Architecture & Connectivity

All services in this stack are connected via the external overlay network `aether-net`. This allows them to communicate with each other and other stacks (like the download stack or ingress proxy) using internal Docker DNS hostnames.

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

### 1. Internal Communication (API & Network)

Services communicate directly over `aether-net` without leaving the cluster or going through the public internet.

*   **Prowlarr ↔ Sonarr / Radarr**
    *   **Direction**: Bidirectional.
    *   **Mechanism**: API Keys.
    *   **Setup**: In Prowlarr, add Sonarr/Radarr as "Applications".
    *   **Address to use**: `http://sonarr:8989` and `http://radarr:7878`.
    *   **Function**: Prowlarr pushes indexer configurations to Sonarr/Radarr. Sonarr/Radarr query Prowlarr (via the pushed indexer URL) to search for content.

*   **Overseerr → Sonarr / Radarr / Plex**
    *   **Direction**: Overseerr initiates connection.
    *   **Mechanism**: API Keys & Authentication.
    *   **Setup**: In Overseerr settings.
    *   **Addresses to use**: `http://sonarr:8989`, `http://radarr:7878`, `http://plex:32400`.
    *   **Function**: Overseerr sends approval commands to Sonarr/Radarr to add shows/movies. It syncs library state and user watch history from Plex.

*   **Sonarr / Radarr → Download Client (External)**
    *   *Note: The download client (e.g., qBittorrent, SABnzbd) is NOT in this stack.*
    *   **Mechanism**: API.
    *   **Address to use**: Assuming it is on `aether-net`, use its service name (e.g., `http://glacier-torrent:8080`).

### 2. Filesystem Access (Bind Mounts)

Physical storage is mounted from the `muspelheim` host into the containers.

*   **Media Access (`/media`)**
    *   **Path**: `/mnt/storage/media` (Host) → `/media` (Container).
    *   **Services**: `plex`, `jellyfin`, `sonarr`, `radarr`.
    *   **Flow**:
        1.  **Sonarr/Radarr** see completed downloads (via mapped path) and **move/copy/hardlink** them to `/media/TV` or `/media/Movies`.
        2.  **Plex/Jellyfin** scan `/media` to play content.
    *   *Note: Prowlarr, Tautulli, and Overseerr do NOT need access to media files.*

*   **Configuration (`/config`)**
    *   **Path**: `/opt/apollo-core/<service_name>` (Host) → `/config` (Container).
    *   **Function**: Persistent storage for application databases and settings.

## Deployment

Deployments are handled automatically via GitHub Actions in `.github/workflows/deploy.yml` which runs on the `gaia` manager node.

### Manual Deployment
```bash
./start.sh
```

### Requirements
- **Node**: `muspelheim` and `manager` must be active in the Swarm.
- **Network**: `docker network create --driver overlay --attachable aether-net` must exist.
- **Host Preparation**:
  Copy `setup_host.sh` to the host (Muspelheim) and run it:
  ```bash
  chmod +x setup_host.sh
  ./setup_host.sh
  ```

## Service Configuration & Onboarding

Once deployed, access each service via its URL (e.g., `https://plex.example.com`) to perform the initial configuration.

### 1. Prowlarr (Indexers)
*   **Initial Setup**: Create an admin account.
*   **Add Indexers**: Go to "Indexers" > "Add Indexer" > Search (e.g., generic public trackers or your private ones).
*   **Connect Clients**: Go to "Settings" > "Apps" > Add Sonarr, Radarr, and Lidarr.
    *   *Prowlarr Host*: `http://prowlarr:9696`
    *   *API Key*: Get from the respective app's "Settings" > "General".

### 2. Sonarr (TV) & Radarr (Movies)
*   **Media Management**: Enable "Rename Files". Add Root Folders:
    *   Sonarr: `/media/TV`
    *   Radarr: `/media/Movies`
*   **Indexers**: These will appear automatically once Prowlarr is configured.
*   **Download Clients**: Connect to your external downloader (e.g., Transmission, qBittorrent).
    *   *Host*: Internal hostname/IP (e.g., `glacier-torrent` or `192.168.x.x`).

### 3. Music (Lidarr)
*   **Media Management**: Enable "Rename Files". Root Folder: `/media/Music`.
*   **Indexers**: Automatic via Prowlarr.
*   **Download Client**: Same as Sonarr/Radarr.


### 5. Plex (Media Server)
*   **Claim Server**:
    *   **Option A (Token)**: Set `PLEX_CLAIM` in `.env` before starting.
    *   **Option B (SSH Tunnel)**: If "Looking for servers" or no setup wizard appears:
        1.  On your local machine, run: `ssh -L 32400:localhost:32400 <user>@<server-ip>`
        2.  Open `http://localhost:32400/web` in your browser.
        3.  You will now see the setup wizard to claim the server and add libraries.
*   **Libraries**: Add libraries pointing to the bind mounts:
    *   **Movies**: `/media/Movies`
    *   **TV Shows**: `/media/TV`
    *   **Music**: `/media/Music`
    *   **Audiobooks**: `/media/Audiobooks`
*   **Remote Access**: Disable "Remote Access" in settings (since Traefik handles it externally), or manually set the public port to 443 if using ingress.

### 6. Jellyfin (Media Server)
*   **Startup Wizard**: Create an admin account.
*   **Libraries**: Add libraries pointing to the bind mounts:
    *   **Movies**: `/media/Movies`
    *   **TV Shows**: `/media/TV`
    *   **Music**: `/media/Music`
    *   **Books**: `/media/Audiobooks` (Jellyfin supports ebooks/audiobooks too)
*   **Remote Access**: No special config needed; Traefik handles it.

### 7. Tautulli (Plex Statistics)
*   **Startup Wizard**: Sign in with your Plex account to link them.
*   **Settings**: Tautulli will automatically monitor the Plex server (since it's on the same network).
*   **Verification**: Ensure it shows "Server Status: Connected".

### 8. Overseerr (Requests)
*   **Login**: Sign in with your Plex account.
*   **Connect Services**:
    *   **Plex**: Host `plex`, Port `32400`.
    *   **Sonarr**: Host `sonarr`, Port `8989`.
    *   **Radarr**: Host `radarr`, Port `7878`.

---

## Sharing & Mobile Apps

### 🎥 Plex
**How to Share**:
1.  Go to **Settings** > **Manage Library Access**.
2.  Click **Grant Library Access**.
3.  Enter the email of the person (they need a free Plex account).

**Client Apps**:
*   **iOS / Android**: "Plex" (Free/Paid).
*   **TV**: Plex is available on almost all Smart TVs, Apple TV, Roku, NVIDIA Shield, Playstation, Xbox.
*   **Web**: `https://app.plex.tv` or your domain.

### 🐬 Jellyfin
**How to Share**:
1.  Go to **Dashboard** > **Users**.
2.  Click **(+)** to create a new user account for your friend/family.
3.  They log in using your server URL (`https://jellyfin.example.com`) and the credentials you made.

**Client Apps**:
*   **iOS**: "Swiftfin" (Recommended) or "Jellyfin Mobile".
*   **Android**: "Findroid" (Recommended) or "Jellyfin".
*   **TV**: "Jellyfin" on Android TV / Roku. "Infuse" (Apple TV - Premium).
*   **Music**: "Finamp" (Mobile).
*   **Audiobooks**: "Prologue" (iOS - Highly Recommended) or "Chronicle" (Android) connected to Plex.

### 📥 Overseerr
**How to Share**:
*   Users log in with their **Plex Account** (if you've granted them access to your Plex server).
*   They can browse trending content and hit "Request".
*   **App**: No native app store app.
    *   **iOS/Android**: Add the website to your Home Screen (PWA). It behaves exactly like an app.

> [!NOTE]
> **Music**: Overseerr **only** supports Movies and TV.
> To request/add Music, you (or trusted users) must use the **Lidarr** interface directly.
> *   **Admin**: Use the web UI or **nzb360/LunaSea**.
> *   **Users**: No specific "request" app exists; they usually ask the Admin.

### 📱 Management (Admin Only)
To manage Sonarr/Radarr/Lidarr from your phone:
*   **Android**: "nzb360" (Highly Recommended).
*   **iOS**: "LunaSea" or "Helmarr".

