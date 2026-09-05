# pangolin

Pangolin is the reverse proxy and tunnel. It terminates TLS and serves every addon in this guide on a real hostname. Deploy it first — it creates the `pangolin_frontend` network other stacks attach to.

Install it from Redhair's guide: [4 Reverse Proxy — Pangolin](https://redhair.gitbook.io/redhair-guides/selfhosting-guide-gui-version#id-4-reverse-proxy-pangolin). There is no compose file in this repo.

## Adding a resource

1. **Resources → Public → Add Resource**
2. **Type:** HTTP
3. **Name** and **Subdomain:** the stack's name — it becomes `<subdomain>.yourdomain.com`
4. **Add Target** — **Host:** the container name, **Port:** the port inside the container
5. **Create Resource**

The values for each service are on its own page.

## Managing Pangolin from Dockhand

Redhair's installer puts Pangolin outside Dockhand's stack folder, so Dockhand shows it as
**Untracked** and can't deploy or edit it. Adopting it fixes that.

**1. Find Pangolin's compose file.**

```bash
docker inspect pangolin --format '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}'
docker inspect pangolin --format '{{ index .Config.Labels "com.docker.compose.project.config_files" }}'
```

Usually `/opt/pangolin`. Use whatever these report.

**2. Mount that directory into Dockhand.** Find Dockhand's own compose the same way:

```bash
docker inspect dockhand --format '{{ index .Config.Labels "com.docker.compose.project.config_files" }}'
```

That compose has two services, `dockhand` and `socket-proxy`. Add the mount under
**`dockhand`**:

```yaml
services:
  dockhand:
    volumes:
      - dockhand_data:/app/data
      - /opt/pangolin:/opt/pangolin
```

Put Pangolin's real path on **both sides of the colon**. Pangolin's compose refers to
`./config`, which only resolves if the path inside the container is the same as the path on
the host.

Then recreate Dockhand only:

```bash
cd "$(docker inspect dockhand --format '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}')"
docker compose up -d --force-recreate dockhand
```

**3. Import it.** In Dockhand: **Stacks → Import** (**Adopt** on older builds) → browse to
Pangolin's directory → select `docker-compose.yml` → confirm, then refresh.

Pangolin flips from **Untracked** to **Internal**. Don't paste the YAML into **Create
stack** instead — that makes a duplicate stack rather than adopting the running one.

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
