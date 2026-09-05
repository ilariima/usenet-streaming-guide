# aiometadata

The metadata provider for the stack — titles, artwork, descriptions and catalogs, served to
Stremio as its own addon on its own public hostname.

Covered in Redhair's guide: [7. Deploying AIOmetadata](https://redhair.gitbook.io/redhair-guides/selfhosting-guide-gui-version#deploying-aiometadata)

## compose.yaml

```yaml
services:
  aiometadata:
    image: ghcr.io/cedya77/aiometadata:latest
    container_name: aiometadata
    restart: unless-stopped
    expose:
      - 3232
    env_file:
      - .env
    volumes:
      - ./aiometadata/data:/app/addon/data
    networks:
      - pangolin_frontend
      - aiometadata
    depends_on:
      aiometadata_redis:
        condition: service_healthy
    tty: true
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3232/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  aiometadata_redis:
    image: redis:latest
    container_name: aiometadata_redis
    restart: unless-stopped
    networks:
      - aiometadata
    expose:
      - 6379
    volumes:
      - ./aiometadata/cache:/data
    command: redis-server --appendonly yes --save 3600 1
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

networks:
  # Created by the Pangolin stack.
  pangolin_frontend:
    external: true
  # Created by this stack. jikan attaches to it as external.
  aiometadata:
    name: aiometadata
```

## .env

```dotenv
# ==============================================================================
# aiometadata — metadata provider addon
# ------------------------------------------------------------------------------
# Copy to .env in this directory, then replace every CHANGEME_ value.
# ==============================================================================

# --- Access control (you invent these) ---
# Two separate credentials for two separate things:
#   ADDON_PASSWORD — gates profile configuration
#   ADMIN_KEY      — gates the admin panel
# They may be the same value, but keeping them different means handing someone a
# configure password doesn't also hand them admin.
# Generate with: openssl rand -hex 16
ADDON_PASSWORD=CHANGEME_ADDON_PASSWORD
ADMIN_KEY=CHANGEME_ADMIN_KEY

# --- Public hostname ---
# The domain this addon is served on. Must match the Pangolin resource you
# create for it, and must resolve publicly — Stremio calls it from the internet.
HOST_NAME=aiometadata.example.com

# --- Backing services (leave as-is unless you renamed containers) ---
REDIS_URL=redis://aiometadata_redis:6379
DATABASE_URI=sqlite://addon/data/db.sqlite

# Local Jikan instance — see docs/jikan.md
# The /v4 suffix is REQUIRED. AIOMetadata appends paths directly to this value,
# so without it every anime lookup 404s.
# The public api.jikan.moe shuts down 1 October 2026 — self-hosting is the only
# option after that.
JIKAN_API_BASE=http://jikan-rest:8080/v4

# --- Simkl (optional) ---
# Register an app at https://simkl.com/oauth/applications
#
# Two flows. SIMKL_AUTH_MODE defaults to `pin` when SIMKL_CLIENT_SECRET is empty
# and `oauth` when it is set.
#   pin   — needs only SIMKL_CLIENT_ID. No secret, no callback.
#   oauth — needs the secret. SIMKL_REDIRECT_URI defaults to
#           ${HOST_NAME}/api/auth/simkl/callback, so you only set it explicitly
#           if you registered a different URI with Simkl.
SIMKL_CLIENT_ID=CHANGEME_SIMKL_CLIENT_ID
SIMKL_CLIENT_SECRET=CHANGEME_SIMKL_CLIENT_SECRET
SIMKL_AUTH_MODE=
SIMKL_REDIRECT_URI=

# --- Trakt (optional) ---
# Register an app at https://trakt.tv/oauth/applications
#
# CREATE A NEW TRAKT APP — do not reuse one you made for something else. Its
# Redirect URI belongs to that app, and the mismatch fails with "invalid
# redirect" even though your .env looks correct.
#
# Register the app with this exact Redirect URI (no trailing slash):
#   https://<HOST_NAME>/api/auth/trakt/callback
#
# Leave TRAKT_REDIRECT_URI blank — it is derived from HOST_NAME, so there is
# only one place to edit. Set it only if you registered something different.
TRAKT_CLIENT_ID=CHANGEME_TRAKT_CLIENT_ID
TRAKT_CLIENT_SECRET=CHANGEME_TRAKT_CLIENT_SECRET
TRAKT_REDIRECT_URI=
```

**Replace:** `HOST_NAME`,
`ADDON_PASSWORD` and `ADMIN_KEY` (`openssl rand -hex 16` each), and the Simkl and
Trakt client IDs and secrets — from
[simkl.com/oauth/applications](https://simkl.com/oauth/applications) and
[trakt.tv/oauth/applications](https://trakt.tv/oauth/applications).

## Deploy

Deploy [pangolin](pangolin.md) first, and this before [jikan](jikan.md) — it creates the
`aiometadata` network jikan attaches to.

1. Dockhand → **Stacks → Create**, name `aiometadata`, paste the compose above, save.
2. Paste the `.env` above into the `.env` panel beside it.
3. Deploy the stack in Dockhand.
4. Trakt: create a **new** app at [trakt.tv/oauth/applications](https://trakt.tv/oauth/applications)
   with Redirect URI `https://<HOST_NAME>/api/auth/trakt/callback` — no trailing slash. Put its
   Client ID and Secret in `.env` and redeploy.
5. Open `https://<HOST_NAME>/configure`, enter `ADDON_PASSWORD`, connect Trakt and Simkl,
   then install the addon URL in Stremio.

## Pangolin resource

| Type | Name | Subdomain | Host | Port |
|---|---|---|---|---|
| HTTP | `aiometadata` | `aiometadata` | `aiometadata` | `3232` |

Resources → Public → Add Resource, then Add Target.
