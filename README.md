# Aspera HSTS Containers

> [!IMPORTANT]
> Experimental as a sample, not for production.

Build and run IBM Aspera High-Speed Transfer Server (HSTS) with Docker Compose: one HSTS container (Node API + SSH/FASP transfers) and one Redis container.

## Prerequisites

- Docker ≥ 24 with Compose v2
- Ruby ≥ 3.0 with `rake`, and the `rpm` command (macOS: `brew install rpm`) — used to read the RPM version and architecture
- An Aspera HSTS RPM placed in `private/` (exactly one)
- An Aspera license: license file or ALEE entitlement (see [License](#license))

## Architecture

```
┌──────────────────────────── aspera-net ────────────────────────────┐
│                                                                    │
│  ┌───────────────┐        ┌─────────────────────────────────────┐  │
│  │ asperaredisd  │<───────│ aspera-hsts  (s6-overlay)           │  │
│  │ redis:7 :31415│        │  asperanoded  Node API HTTPS :9092  │  │
│  └───────────────┘        │  sshd + ascp  SSH :22, FASP :33001/u│  │
│                           └─────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────┘
```

### Containers

| Container | Process(es) | Port(s) | Description |
| --- | --- | --- | --- |
| `asperaredisd` | `redis-server` (stock `redis:7-alpine`) | 31415/tcp (internal) | Node API database |
| `aspera-hsts` | `asperanoded`, `sshd` (+ `ascp` per transfer) | 9092/tcp, 22/tcp, 33001/udp | Node API (HTTPS), SSH/FASP transfers |

Inside `aspera-hsts`, [s6-overlay](https://github.com/just-containers/s6-overlay) runs these services ([`rootfs/etc/s6-overlay/s6-rc.d`](rootfs/etc/s6-overlay/s6-rc.d)):

| Service | Type | Role |
| --- | --- | --- |
| `syslog-bridge` | longrun | Copies syslog messages from `/dev/log` to the container's stdout |
| `init-aspera-hsts` | oneshot | Prepares volumes and configuration (see below); the container stops if it fails |
| `asperanoded` | longrun | Node API, as `asperadaemon` |
| `sshd` | longrun | SSH for `ascp`, key authentication only, user `xfer` with `aspshell` |

At each start, `init-aspera-hsts`:

- populates empty volumes from the image defaults and removes stale PID files
- points `asperanoded` to the Redis container (`db_host`, `db_port`)
- generates, on first start, the Node API TLS key pair and the SSH host keys (stored in the `etc` volume)
- writes `XFER_AUTHORIZED_KEYS` to `xfer`'s `authorized_keys` and sets `xfer`'s docroot
- installs the license (if provided)
- creates or updates the Node API user `NODE_USER`, mapped to `xfer`

### Volumes

| Volume | Mounted in | Content |
| --- | --- | --- |
| `aspera-etc` | aspera-hsts: `/opt/aspera/etc` | `aspera.conf`, license, TLS key pair, SSH host keys |
| `aspera-var` | aspera-hsts: `/opt/aspera/var` | Runtime state, logs, token keys |
| `redis-data` | asperaredisd: `/data` | Redis database (Node API users, transfer history) |

Transferred files are stored in `XFER_DOCROOT` (default `/home/xfer`), which is not a volume.

### Logging

Aspera processes log via syslog. The `syslog-bridge` service listens on `/dev/log` and writes one line per message to stdout, so logs are available with `docker compose logs` or any log driver (Loki, CloudWatch, Splunk…).

## Quickstart

```bash
# 1. Create the configuration
cp .env.example .env
# Edit .env: NODE_PASS, XFER_AUTHORIZED_KEYS, license...

# 2. Build the image
rake build

# 3. Start
docker compose up -d

# 4. Check
docker compose ps
docker compose logs -f
curl -k -u "nodeuser:<NODE_PASS>" https://localhost:9092/info
```

## Rake tasks

```
rake build          # Build the aspera-hsts image (default task), for the RPM's architecture
rake push           # Push the image to REGISTRY
rake compose:up     # docker compose up -d
rake compose:down   # docker compose down
rake compose:logs   # docker compose logs -f
rake pdf            # Generate README.pdf from README.md
```

`rake pdf` uses gfm2pdf-toolchain: set `GFM2PDF_DIR` to its folder (default: `../gfm2pdf-toolchain`, next to this repository), and `GFM2PDF_ENGINE` to select the PDF engine (`latex` or `typst`).

## Environment variables

See [`.env.example`](.env.example).

| Variable | Default | Description |
| --- | --- | --- |
| `REGISTRY` | `localhost` | Docker registry |
| `TAG` | RPM version (rake), `latest` (compose) | Image tag |
| `NODE_USER` | `nodeuser` | Node API user |
| `NODE_PASS` | *(required)* | Node API password: 16-92 ASCII characters, at least 2 lowercase, 2 uppercase, 2 digits |
| `NODE_PORT` | `9092` | Node API HTTPS port (host) |
| `ASCP_SSH_PORT` | `33001` | SSH port (host) |
| `FASP_UDP_PORT` | `33001` | FASP UDP port (host) |
| `XFER_AUTHORIZED_KEYS` | *(empty)* | SSH public key(s) for `xfer` |
| `XFER_DOCROOT` | `/home/xfer` | Docroot of `xfer` |
| `ASPERA_LICENSE` | *(empty)* | Content of a license file |
| `ASPERA_CUSTOMER_ID`, `ASPERA_ENTITLEMENT_ID` | *(empty)* | ALEE entitlement, registered with `alee-admin` |

## License

Without a license, `asperanoded` answers every request (including `/ping`, so the healthcheck fails) with `Invalid server configuration: License issue`, and transfers are refused. Provide one of:

- `ASPERA_LICENSE`: content of the license file, written to `/opt/aspera/etc/aspera-license` at each start
- `ASPERA_CUSTOMER_ID` and `ASPERA_ENTITLEMENT_ID`: registered with `alee-admin register` at each start
- or copy a license file into the `etc` volume: `docker compose cp aspera-license aspera-hsts:/opt/aspera/etc/aspera-license`
