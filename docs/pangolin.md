# pangolin

Pangolin is the reverse proxy and tunnel. It terminates TLS and serves every addon in this guide on a real hostname. Deploy it first — it creates the `pangolin_frontend` network other stacks attach to.

Install it from Redhair's guide: [4 Reverse Proxy — Pangolin](https://redhair.gitbook.io/redhair-guides/selfhosting-guide-gui-version#id-4-reverse-proxy-pangolin). There is no compose file in this repo.

## Adding a resource

1. **Resources → Public → Add Resource**
2. **Type:** HTTP
3. **Name** and **Subdomain:** the stack's name — it becomes `<subdomain>.yourdomain.com`
4. **Add Target** — **Host:** the container name, **Port:** the port inside the container
5. **Create Resource**

Resources this guide needs:

| Name / Subdomain | Host | Port |
|---|---|---|
| `aiostreams` | `aiostreams` | `3000` |
| `aiometadata` | `aiometadata` | `3232` |
| `aiomanager` | `aiomanager` | `1610` |
| `beszel` | `beszel` | `8090` |
| `dockhand` | `dockhand` | `3000` |

Create beszel's resource before finishing its setup — its token and key come from the hub web UI.

## Updating Pangolin

Versions are pinned. Change the pins first, then pull. Check the [release notes](https://docs.pangolin.net/self-host/how-to-update) — some releases need config changes.

In `docker-compose.yml`:

```yaml
services:
  pangolin:
    image: fosrl/pangolin:<pangolin-version>
  gerbil:
    image: fosrl/gerbil:<gerbil-version>
  traefik:
    image: traefik:<traefik-version>
```

In `config/traefik/traefik_config.yml`:

```yaml
experimental:
  plugins:
    badger:
      moduleName: github.com/fosrl/badger
      version: v<badger-version>
```

Then, from your Pangolin directory:

```bash
cd /opt/pangolin
docker compose down
nano docker-compose.yml
nano config/traefik/traefik_config.yml
docker compose pull
docker compose up -d
```
