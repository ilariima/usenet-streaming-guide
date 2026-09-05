# wireguard

A WireGuard VPN server for reaching the host — SSH, Dockhand, and anything else not published
publicly — from your phone or laptop.

## compose.yaml

```yaml
services:
  wireguard:
    image: lscr.io/linuxserver/wireguard:latest
    container_name: wireguard

    cap_add:
      - NET_ADMIN
      - SYS_MODULE

    env_file:
      - .env

    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
      - SERVERURL=${SERVERURL}
      - SERVERPORT=${SERVERPORT}
      - PEERS=${PEERS}
      - PEERDNS=${PEERDNS}
      - INTERNAL_SUBNET=${INTERNAL_SUBNET}
      - ALLOWEDIPS=${ALLOWEDIPS}
      - LOG_CONFS=${LOG_CONFS}

    volumes:
      - ${CONFIG_PATH}:/config
      - /lib/modules:/lib/modules

    ports:
      # Host port comes from SERVERPORT so it always matches the peer configs.
      - ${SERVERPORT}:51820/udp

    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1

    restart: unless-stopped
```

## .env

```dotenv
# ==============================================================================
# wireguard — VPN server for remote access to your host
# ------------------------------------------------------------------------------
# Copy to .env, then set SERVERURL. Everything else has a working default.
# ==============================================================================

# --- The one value you must set ---
# The public IP or hostname your phone/laptop will connect to. This is baked
# into every peer config that gets generated, so a wrong value produces client
# configs that never connect.
SERVERURL=CHANGEME_YOUR_PUBLIC_IP_OR_HOSTNAME

# --- Listening port ---
# The UDP port on the host, and the port written into peer configs. Must be open
# in your firewall AND your cloud provider's security rules.
SERVERPORT=51821

# --- Peers ---
# How many client configs to generate. Each gets its own config file and QR code.
# Raising this later generates the new ones on restart; lowering it does not
# delete existing peers.
PEERS=1

# --- Client settings, written into each peer config ---
# DNS the client uses while connected.
PEERDNS=1.1.1.1
# 0.0.0.0/0,::/0 sends ALL client traffic through the tunnel.
# Use 10.13.13.0/24 instead to reach only this server, leaving normal browsing
# on the client's own connection.
ALLOWEDIPS=0.0.0.0/0,::/0

# --- Tunnel network ---
# The private subnet used inside the tunnel. Change it only if it collides with
# a network you already use.
INTERNAL_SUBNET=10.13.13.0

# --- Host ---
PUID=1000
PGID=1000
TZ=Etc/UTC

# Where peer configs and server keys are stored, relative to this file.
CONFIG_PATH=./config

# Prints peer configs and QR codes to the container log on start.
LOG_CONFS=true
```

**Replace:** `SERVERURL`.

## Deploy

1. Open UDP `51821` in the host firewall and in your cloud provider's firewall.

   ```bash
   sudo ufw allow 51821/udp
   ```

2. Create the stack in Dockhand and paste the compose above.

3. Paste the `.env` above into the `.env` panel beside it.

4. Deploy the stack in Dockhand.

5. Read the peer config out of the log — scan the QR code with the WireGuard mobile app, or
   import the printed config on a laptop.

   ```bash
   docker logs wireguard
   ```
