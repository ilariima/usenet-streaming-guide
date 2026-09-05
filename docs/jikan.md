# jikan

Self-hosted MyAnimeList API. AIOMetadata uses it for anime metadata instead of the rate-limited public `api.jikan.moe`.

Deploy [aiometadata](aiometadata.md) first — it creates the `aiometadata` network.

## compose.yaml

```yaml
services:
  jikan-mongodb:
    image: mongo:focal
    container_name: jikan-mongodb
    hostname: mongodb
    restart: unless-stopped
    env_file:
      - .env
    environment:
      - MONGO_INITDB_ROOT_USERNAME=${MONGO_USER}
      - MONGO_INITDB_ROOT_PASSWORD=${MONGO_PASSWORD}
      - MONGO_INITDB_DATABASE=${MONGO_DATABASE}
    command: "--wiredTigerCacheSizeGB 1.0"
    volumes:
      - jikan_mongo:/data/db
    networks:
      - jikan
    healthcheck:
      test: ['CMD-SHELL', 'mongosh mongodb://localhost:27017 --quiet --eval "db.runCommand(\"ping\").ok"']
      interval: 30s
      timeout: 10s
      retries: 5

  jikan-redis:
    image: redis:6-alpine
    container_name: jikan-redis
    hostname: redis
    restart: unless-stopped
    env_file:
      - .env
    command: ["sh", "-c", "redis-server --requirepass \"$REDIS_PASSWORD\""]
    volumes:
      - jikan_redis:/data
    networks:
      - jikan
    healthcheck:
      test: ['CMD-SHELL', 'redis-cli -a "$REDIS_PASSWORD" ping | grep -q PONG']
      interval: 5s
      timeout: 3s

  jikan-typesense:
    image: typesense/typesense:0.24.1
    container_name: jikan-typesense
    hostname: typesense
    restart: unless-stopped
    env_file:
      - .env
    environment:
      - TYPESENSE_DATA_DIR=/data
      - TYPESENSE_API_KEY=${TYPESENSE_API_KEY}
      - TYPESENSE_ENABLE_CORS=true
    volumes:
      - jikan_typesense:/data
    networks:
      - jikan

  jikan-rest:
    image: jikanme/jikan-rest:latest
    container_name: jikan-rest
    hostname: jikan-rest-api
    restart: unless-stopped
    env_file:
      - .env
    environment:
      - APP_ENV=production
      - APP_DEBUG=false
      - LOG_LEVEL=info
      - CACHING=true
      - CACHE_DRIVER=redis
      - REDIS_HOST=redis
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - REDIS_PORT=6379
      - DB_CONNECTION=mongodb
      - DB_HOST=mongodb
      - DB_PORT=27017
      - DB_DATABASE=${MONGO_DATABASE}
      - DB_USERNAME=${MONGO_USER}
      - DB_ADMIN=admin
      - DB_PASSWORD=${MONGO_PASSWORD}
      - SCOUT_DRIVER=typesense
      - SCOUT_QUEUE=false
      - TYPESENSE_HOST=typesense
      - TYPESENSE_PORT=8108
      - TYPESENSE_API_KEY=${TYPESENSE_API_KEY}
      - CORS_MIDDLEWARE=true
      - MICROCACHING=true
      - MICROCACHING_EXPIRE=60
    depends_on:
      jikan-mongodb:
        condition: service_healthy
      jikan-redis:
        condition: service_healthy
      jikan-typesense:
        condition: service_started
    networks:
      - jikan
      - aiometadata

networks:
  jikan:
    driver: bridge
  # The network your consumer app already runs on. Rename to match yours, or
  # delete this entry (and the reference above) to run Jikan self-contained.
  aiometadata:
    external: true

volumes:
  jikan_mongo:
  jikan_redis:
  jikan_typesense:
```

## .env

```dotenv
# ==============================================================================
# jikan — self-hosted MyAnimeList API
# ------------------------------------------------------------------------------
# Copy to .env in this directory, then replace every CHANGEME_ value.
# All values here are ones YOU invent — nothing needs to be obtained from a
# third party. Use long random strings.
#
#   Generate one:  openssl rand -hex 24
#
# Use -hex, NOT -base64: base64 can emit / and +, which break the MongoDB
# connection string jikan-rest builds from these values.
# ==============================================================================

# --- MongoDB (cached anime/manga data) ---
# Applied ONLY on first run, while the jikan_mongo volume is empty.
# Changing these later does nothing unless you wipe the volume.
MONGO_USER=jikan
MONGO_PASSWORD=CHANGEME_MONGO_PASSWORD
MONGO_DATABASE=jikan

# --- Redis (cache layer) ---
REDIS_PASSWORD=CHANGEME_REDIS_PASSWORD

# --- Typesense (search engine) ---
TYPESENSE_API_KEY=CHANGEME_TYPESENSE_KEY
```

| Variable | What to put |
|---|---|
| `MONGO_PASSWORD` | `openssl rand -hex 24` |
| `REDIS_PASSWORD` | `openssl rand -hex 24` |
| `TYPESENSE_API_KEY` | `openssl rand -hex 24` |

## Deploy

1. Dockhand → Stacks → Add Stack, name it `jikan`, paste the compose.
2. Create the `.env` in the stack directory over SSH:

   ```bash
   nano /opt/dockhand/stacks/jikan/.env
   ```

3. Deploy the stack in Dockhand.
4. Seed the Typesense index — without this, search, seasonal, top and genre catalogs return nothing:

   ```bash
   docker exec jikan-rest php artisan indexer:genres
   docker exec jikan-rest php artisan indexer:common
   docker exec jikan-rest php artisan indexer:anime-current-season
   ```

5. In [aiometadata](aiometadata.md), set `JIKAN_API_BASE=http://jikan-rest:8080/v4` and redeploy.

Re-run `indexer:anime-current-season` each season.
