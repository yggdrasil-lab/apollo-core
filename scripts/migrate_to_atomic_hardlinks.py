#!/usr/bin/env python3
"""
Migrate Sonarr, Radarr, and Lidarr to TRaSH Guides unified root mount (/data)
for instant zero-copy atomic hardlinks.

Usage:
  # Dry-run (inspect changes without applying):
  python3 scripts/migrate_to_atomic_hardlinks.py --dry-run

  # Apply migration:
  python3 scripts/migrate_to_atomic_hardlinks.py --apply
"""

import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request


def api_request(base_url, endpoint, api_key, method="GET", payload=None):
    url = f"{base_url.rstrip('/')}/api/v3/{endpoint.lstrip('/')}"
    headers = {
        "X-Api-Key": api_key,
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    data = json.dumps(payload).encode("utf-8") if payload is not None else None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            content = resp.read().decode("utf-8")
            return json.loads(content) if content else {}
    except urllib.error.HTTPError as e:
        err_msg = e.read().decode("utf-8")
        print(f"[-] HTTP {e.code} on {method} {url}: {err_msg}", file=sys.stderr)
        raise
    except Exception as e:
        print(f"[-] Error connecting to {url}: {e}", file=sys.stderr)
        raise


def ensure_root_folder(base_url, api_key, target_path, dry_run=False):
    root_folders = api_request(base_url, "rootfolder", api_key)
    for rf in root_folders:
        if rf.get("path") == target_path:
            print(f"[+] Root folder already exists: {target_path} (ID: {rf.get('id')})")
            return rf.get("id")

    print(f"[*] Adding root folder: {target_path}")
    if dry_run:
        return 999
    res = api_request(base_url, "rootfolder", api_key, method="POST", payload={"path": target_path})
    return res.get("id")


def ensure_remote_path_mapping(base_url, api_key, host, remote_path, local_path, dry_run=False):
    mappings = api_request(base_url, "remotepathmapping", api_key)
    for m in mappings:
        if m.get("host") == host and m.get("remotePath") == remote_path and m.get("localPath") == local_path:
            print(f"[+] Remote path mapping already exists for {host}: {remote_path} -> {local_path}")
            return

    print(f"[*] Adding Remote Path Mapping for {host}: {remote_path} -> {local_path}")
    if dry_run:
        return
    payload = {
        "host": host,
        "remotePath": remote_path,
        "localPath": local_path,
    }
    api_request(base_url, "remotepathmapping", api_key, method="POST", payload=payload)


def migrate_sonarr(base_url, api_key, dry_run=False):
    print("\n=== Migrating Sonarr ===")
    try:
        ensure_root_folder(base_url, api_key, "/data/media/TV", dry_run=dry_run)
        ensure_remote_path_mapping(base_url, api_key, "gluetun", "/downloads/", "/data/downloads/", dry_run=dry_run)
        ensure_remote_path_mapping(base_url, api_key, "qbittorrent", "/downloads/", "/data/downloads/", dry_run=dry_run)

        series_list = api_request(base_url, "series", api_key)
        to_migrate = [s for s in series_list if not s.get("path", "").startswith("/data/")]
        print(f"[*] Found {len(series_list)} total series ({len(to_migrate)} needing path update to /data/media/TV)")

        if to_migrate:
            ids = [s["id"] for s in to_migrate]
            print(f"[*] Updating {len(ids)} series to root folder '/data/media/TV' (moveFiles: false)...")
            if not dry_run:
                payload = {
                    "seriesIds": ids,
                    "rootFolderPath": "/data/media/TV",
                    "moveFiles": False,
                }
                api_request(base_url, "series/editor", api_key, method="PUT", payload=payload)
                print("[+] Sonarr series paths successfully updated!")
            else:
                print("[DRY-RUN] Skipped API PUT to /series/editor.")
        else:
            print("[+] All Sonarr series already use /data/ mount.")
    except Exception as e:
        print(f"[-] Sonarr migration error: {e}")


def migrate_radarr(base_url, api_key, dry_run=False):
    print("\n=== Migrating Radarr ===")
    try:
        ensure_root_folder(base_url, api_key, "/data/media/Movies", dry_run=dry_run)
        ensure_remote_path_mapping(base_url, api_key, "gluetun", "/downloads/", "/data/downloads/", dry_run=dry_run)
        ensure_remote_path_mapping(base_url, api_key, "qbittorrent", "/downloads/", "/data/downloads/", dry_run=dry_run)

        movies = api_request(base_url, "movie", api_key)
        to_migrate = [m for m in movies if not m.get("path", "").startswith("/data/")]
        print(f"[*] Found {len(movies)} total movies ({len(to_migrate)} needing path update to /data/media/Movies)")

        if to_migrate:
            ids = [m["id"] for m in to_migrate]
            print(f"[*] Updating {len(ids)} movies to root folder '/data/media/Movies' (moveFiles: false)...")
            if not dry_run:
                payload = {
                    "movieIds": ids,
                    "rootFolderPath": "/data/media/Movies",
                    "moveFiles": False,
                }
                api_request(base_url, "movie/editor", api_key, method="PUT", payload=payload)
                print("[+] Radarr movie paths successfully updated!")
            else:
                print("[DRY-RUN] Skipped API PUT to /movie/editor.")
        else:
            print("[+] All Radarr movies already use /data/ mount.")
    except Exception as e:
        print(f"[-] Radarr migration error: {e}")


def migrate_lidarr(base_url, api_key, dry_run=False):
    print("\n=== Migrating Lidarr ===")
    try:
        ensure_root_folder(base_url, api_key, "/data/media/Music", dry_run=dry_run)
        ensure_remote_path_mapping(base_url, api_key, "gluetun", "/downloads/", "/data/downloads/", dry_run=dry_run)
        ensure_remote_path_mapping(base_url, api_key, "qbittorrent", "/downloads/", "/data/downloads/", dry_run=dry_run)

        artists = api_request(base_url, "artist", api_key)
        to_migrate = [a for a in artists if not a.get("path", "").startswith("/data/")]
        print(f"[*] Found {len(artists)} total artists ({len(to_migrate)} needing path update to /data/media/Music)")

        if to_migrate:
            ids = [a["id"] for a in to_migrate]
            print(f"[*] Updating {len(ids)} artists to root folder '/data/media/Music' (moveFiles: false)...")
            if not dry_run:
                payload = {
                    "artistIds": ids,
                    "rootFolderPath": "/data/media/Music",
                    "moveFiles": False,
                }
                api_request(base_url, "artist/editor", api_key, method="PUT", payload=payload)
                print("[+] Lidarr artist paths successfully updated!")
            else:
                print("[DRY-RUN] Skipped API PUT to /artist/editor.")
        else:
            print("[+] All Lidarr artists already use /data/ mount.")
    except Exception as e:
        print(f"[-] Lidarr migration error: {e}")


def main():
    parser = argparse.ArgumentParser(description="Migrate Arr applications to unified /data mount for atomic hardlinks.")
    parser.add_argument("--apply", action="store_true", help="Apply the migration changes via REST APIs.")
    parser.add_argument("--dry-run", action="store_true", help="Inspect what would be changed without writing.")
    parser.add_argument("--sonarr-url", default=os.getenv("SONARR_URL", "http://sonarr:8989"), help="Sonarr base URL")
    parser.add_argument("--sonarr-key", default=os.getenv("SONARR_API_KEY", ""), help="Sonarr API Key")
    parser.add_argument("--radarr-url", default=os.getenv("RADARR_URL", "http://radarr:7878"), help="Radarr base URL")
    parser.add_argument("--radarr-key", default=os.getenv("RADARR_API_KEY", ""), help="Radarr API Key")
    parser.add_argument("--lidarr-url", default=os.getenv("LIDARR_URL", "http://lidarr:8686"), help="Lidarr base URL")
    parser.add_argument("--lidarr-key", default=os.getenv("LIDARR_API_KEY", ""), help="Lidarr API Key")

    args = parser.parse_args()

    if not args.apply and not args.dry_run:
        print("Please specify either --apply or --dry-run.")
        sys.exit(1)

    dry_run = args.dry_run

    if args.sonarr_key:
        migrate_sonarr(args.sonarr_url, args.sonarr_key, dry_run=dry_run)
    else:
        print("[-] Skipping Sonarr: SONARR_API_KEY not provided.")

    if args.radarr_key:
        migrate_radarr(args.radarr_url, args.radarr_key, dry_run=dry_run)
    else:
        print("[-] Skipping Radarr: RADARR_API_KEY not provided.")

    if args.lidarr_key:
        migrate_lidarr(args.lidarr_url, args.lidarr_key, dry_run=dry_run)
    else:
        print("[-] Skipping Lidarr: LIDARR_API_KEY not provided.")

    print("\n[+] Migration routine completed.")


if __name__ == "__main__":
    main()
