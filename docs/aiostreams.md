# aiostreams

AIOStreams aggregates every stream source into a single Stremio addon. It is the addon you install in Stremio.

Covered in Redhair's guide: [6 AIOStreams](https://redhair.gitbook.io/redhair-guides/selfhosting-guide-gui-version#id-6-aiostreams)

Deploy [pangolin](pangolin.md) and [gluetun](gluetun.md) first — this stack attaches to the `pangolin_frontend` and `gluetun` networks they create. It creates the `aiostreams` network.

## compose.yaml

```yaml
services:
  aiostreams:
    image: ghcr.io/viren070/aiostreams:nightly
    container_name: aiostreams
    restart: unless-stopped
    expose:
      - 3000
    env_file:
      - .env
    volumes:
      - ./data:/app/data
    networks:
      - pangolin_frontend
      - aiostreams
      - gluetun

networks:
  # Created by the Pangolin stack.
  pangolin_frontend:
    external: true
  # Created by this stack. Other addons attach to it as external.
  aiostreams:
    name: aiostreams
  # Created by the gluetun stack.
  gluetun:
    external: true
```

## .env

```dotenv
# ==============================================================================
# aiostreams
# Copy to .env, then replace every CHANGEME_ value.
# ==============================================================================

# --- Public URL (required) ---
# Full URL including protocol. Must match the hostname on your Pangolin
# resource. Stremio calls this from the internet.
BASE_URL=https://aiostreams.example.com

# --- Dashboard login (optional) ---
# Comma-separated user:password pairs, e.g. alice:pass1,bob:pass2
# Omit entirely to leave the dashboard unauthenticated.
AIOSTREAMS_AUTH=admin:CHANGEME_PASSWORD

# --- Encryption key (required) ---
# 64-character hex string. Startup fails without it.
# Generate: openssl rand -hex 32
#
# WARNING: changing this after first run makes every existing encrypted
# configuration permanently undecryptable. Set it once, back it up.
SECRET_KEY=CHANGEME_RUN_openssl_rand_hex_32
```

| Variable | What to put |
|---|---|
| `BASE_URL` | Your public URL, e.g. `https://aiostreams.yourdomain.com` — must match the Pangolin resource hostname. |
| `AIOSTREAMS_AUTH` | `user:password` for the dashboard. |
| `SECRET_KEY` | Output of `openssl rand -hex 32`. Set once, keep it. |

## Deploy

1. Generate the key:

   ```bash
   openssl rand -hex 32
   ```

2. In Dockhand, create a stack named `aiostreams` and paste the compose above.

3. Over SSH, write the `.env` in the stack directory:

   ```bash
   nano /opt/dockhand/stacks/aiostreams/.env
   ```

4. Deploy the stack in Dockhand.

5. Open `BASE_URL`, log in, and configure the addon from the dashboard — follow [Redhair 6.2](https://redhair.gitbook.io/redhair-guides/selfhosting-guide-gui-version#setting-up-auth-and-reverse-proxy-for-aiostreams). Install the generated manifest URL in Stremio.

## Pangolin resource

| Type | Name | Subdomain | Host | Port |
|---|---|---|---|---|
| HTTP | aiostreams | aiostreams | aiostreams | 3000 |

Resources → Public → Add Resource, then Add Target.
