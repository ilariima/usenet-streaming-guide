# gluetun

Holds a WireGuard tunnel to your VPN provider and exposes an HTTP proxy on `gluetun:8888` for other containers to route through.

## compose.yaml

```yaml
services:
  gluetun:
    image: qmcgaw/gluetun:latest
    container_name: gluetun
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    environment:
      - VPN_SERVICE_PROVIDER=custom
      - VPN_TYPE=wireguard
      - HTTPPROXY=on
      - HTTPPROXY_LISTENING_ADDRESS=:8888
    env_file:
      - .env
    networks:
      - gluetun
    restart: unless-stopped

networks:
  # Created by this stack. `name:` pins the literal network name so consumers can
  # attach to it as `external: true` — without it compose would prefix the
  # project name and produce e.g. `gluetun_gluetun`.
  gluetun:
    name: gluetun
```

## .env

```dotenv
# ==============================================================================
# gluetun — VPN gateway
# ------------------------------------------------------------------------------
# Copy to .env, then replace every CHANGEME_ value.
#
# These come from your VPN provider's WireGuard config file. If they gave you a
# .conf, every value below is in it:
#
#   [Interface]
#   PrivateKey = ...   ->  WIREGUARD_PRIVATE_KEY
#   Address    = ...   ->  WIREGUARD_ADDRESSES
#   MTU        = ...   ->  WIREGUARD_MTU
#   [Peer]
#   PublicKey  = ...   ->  WIREGUARD_PUBLIC_KEY   (the SERVER's key, not yours)
#   Endpoint   = ip:port -> WIREGUARD_ENDPOINT_IP + WIREGUARD_ENDPOINT_PORT
#   AllowedIPs = ...   ->  WIREGUARD_ALLOWED_IPS
#   PresharedKey = ... ->  WIREGUARD_PRESHARED_KEY  (only if present)
#   DNS        = ...   ->  DNS_ADDRESS              (only if present)
# ==============================================================================

# --- Your client keypair / address ---
WIREGUARD_PRIVATE_KEY=CHANGEME_WIREGUARD_PRIVATE_KEY
WIREGUARD_ADDRESSES=10.0.0.2/24

# --- The VPN server you connect to ---
WIREGUARD_PUBLIC_KEY=CHANGEME_SERVER_PUBLIC_KEY
# Only if your provider's [Peer] block has a PresharedKey line:
#WIREGUARD_PRESHARED_KEY=
WIREGUARD_ENDPOINT_IP=203.0.113.10
WIREGUARD_ENDPOINT_PORT=51820

# --- Tunnel tuning ---
# 0.0.0.0/0 routes all IPv4 through the tunnel.
WIREGUARD_ALLOWED_IPS=0.0.0.0/0
# Keeps the tunnel alive through NAT. 25s is the usual value.
WIREGUARD_PERSISTENT_KEEPALIVE_INTERVAL=25s
# Lower this if connections hang on large transfers. Max 1440.
WIREGUARD_MTU=1320

# --- HTTP proxy logging ---
HTTPPROXY_LOG=on

# --- DNS (optional) ---
# The resolver gluetun forwards queries to. Use the DNS line from your provider's
# WireGuard config if it has one, or pick any resolver you trust.
#DNS_ADDRESS=1.1.1.1
#
# Setting DNS_ADDRESS makes gluetun use plain UDP DNS instead of its default
# DNS-over-TLS. The queries still go through the VPN tunnel. To keep DoT and just
# change resolver, leave DNS_ADDRESS unset and use this instead:
#DNS_UPSTREAM_RESOLVERS=quad9
```

**Replace:** every `WIREGUARD_` value, from your VPN provider's WireGuard config.

Every value comes from your provider's WireGuard `.conf`:


## Deploy

Deploy this stack before any stack that attaches to the `gluetun` network.

1. Dockhand → new stack `gluetun`, paste the compose above.
2. Paste the `.env` above into the `.env` panel beside it.
3. Deploy the stack in Dockhand.
4. In each consumer app's own settings, set its outbound HTTP proxy to `http://gluetun:8888`.
