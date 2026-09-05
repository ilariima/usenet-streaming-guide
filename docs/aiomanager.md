# aiomanager

Account manager for Stremio: multiple identities, addon config snapshots, bulk actions and
watch history, backed by its own PostgreSQL container.

## compose.yaml

```yaml
services:
  aiomanager:
    image: ghcr.io/sonicx161/aiomanager:beta
    container_name: aiomanager
    restart: unless-stopped
    ports:
      - "1610:1610"
    env_file:
      - .env
    environment:
      # Password must match POSTGRES_PASSWORD below.
      - DATABASE_URL=postgres://aio_user:CHANGEME_DB_PASSWORD@aiomanager-db:5432/aio_manager
    volumes:
      - ./aio-data:/app/data
    healthcheck:
      # NOTE: If you use Traefik/Reverse Proxies and see 404s, remove the healthcheck block.
      test: [ "CMD", "/nodejs/bin/node", "server/healthcheck.js" ]
      interval: 1m
      timeout: 10s
      retries: 5
      start_period: 15s
    depends_on:
      aiomanager-db:
        condition: service_healthy
    networks:
      - default
      - pangolin_frontend

  # --- Internal PostgreSQL Service ---
  aiomanager-db:
    image: postgres:16-alpine
    container_name: aiomanager_db
    restart: unless-stopped
    environment:
      - POSTGRES_USER=aio_user
      # Must match the password in DATABASE_URL above.
      - POSTGRES_PASSWORD=CHANGEME_DB_PASSWORD
      - POSTGRES_DB=aio_manager
    volumes:
      - ./aio-db-data:/var/lib/postgresql/data
    healthcheck:
      test: [ "CMD-SHELL", "pg_isready -U aio_user -d aio_manager" ]
      interval: 10s
      timeout: 5s
      retries: 5

networks:
  pangolin_frontend:
    external: true
```

## .env

```dotenv
# ==============================================================================
# aiomanager
# Copy to .env, then replace every CHANGEME_ value.
# ==============================================================================

# --- Server ---
PORT=1610
NODE_ENV=production

# --- Database ---
DB_TYPE=postgres

# Leave empty. compose.yaml sets DATABASE_URL for the bundled Postgres
# container, and that value wins over anything set here.
DATABASE_URL=

# SQLite fallback paths — ignored while DB_TYPE=postgres.
# DATA_DIR must match the volume mount in compose.yaml.
DATA_DIR=/app/data
DB_FILENAME=aio.db

# --- Limits ---
# Max encrypted sync blob, in bytes. Default 104857600 (100 MB).
MAX_SYNC_PAYLOAD_SIZE=104857600
# Outgoing request timeout, in milliseconds.
MAX_TIMEOUT=20000

# --- Encryption ---
# Encrypts sensitive data at rest. Leave empty and the server generates one on
# first run, saved to DATA_DIR/server_secret.key. Back that file up.
ENCRYPTION_KEY=

# --- CORS ---
# Comma-separated allowed origins, or * for all.
CORS_ORIGINS=*

# --- Custom HTML banner on the login page (optional) ---
CUSTOM_HTML=

# --- Logging ---
# fatal | error | warn | info | debug | trace
LOG_LEVEL=info
LOG_PRETTY_PRINT=true
```

**Nothing to replace.** The Postgres password is set in `compose.yaml`, not here.

## Deploy

Deploy the pangolin stack first — it creates the `pangolin_frontend` network.

1. Generate a database password:

   ```bash
   openssl rand -hex 16
   ```

2. In Dockhand, create a stack named `aiomanager` and paste the compose above. Replace
   `CHANGEME_DB_PASSWORD` in **both** places — `DATABASE_URL` and `POSTGRES_PASSWORD` —
   with that same value.

3. Paste the `.env` above into the `.env` panel beside it:

   ```bash
   nano /opt/dockhand/stacks/aiomanager/.env
   ```

4. Deploy the stack in Dockhand.

## Pangolin resource

| Type | Name | Subdomain | Host | Port |
|---|---|---|---|---|
| HTTP | aiomanager | aiomanager | aiomanager | 1610 |

Resources → Public → Add Resource, then Add Target.
