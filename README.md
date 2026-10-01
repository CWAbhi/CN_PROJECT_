# Computer Networks — Phase 1

A private-LAN networking architecture demonstrating core computer networking concepts using four macOS machines on a shared Wi-Fi network. This project implements:

- **Private DNS** — custom `dnsmasq` resolver for the `.test` domain
- **REST Backends** — two Python HTTP servers with JSON API endpoints
- **nginx Reverse Proxy** — edge server terminating HTTPS and forwarding to backends
- **Round-Robin Load Balancing** — nginx distributes requests across Backend A and Backend B
- **HTTPS / TLS** — self-signed CA with trusted certificates; TLS 1.2 on the edge
- **HTTP Caching** — `Cache-Control`, `ETag`, and `304 Not Modified` conditional responses
- **Wireshark Packet Analysis** — DNS, TCP, and TLS packet captures for protocol evidence

---

## Team Members

1. **Abhijeet Dey**
2. **Aditya Ranjan**
3. **Samriddhi Shah**
4. **Satwik Mani Triphati**

---

## Project Architecture

### Network Topology

```
                           Private Wi-Fi / LAN
      ┌────────────────────────────────────────────────────────┐
      │                                                        │
      │ Mac 1: DNS + Client           Mac 4: Backend B + Client│
      │ 10.3.3.225                    10.7.5.29                │
      │ DNS port 53                   HTTP port 3002           │
      │     │ DNS query                   │                    │
      │     └─────┐                       │                    │
      │           ▼                       │                    │
      │       app.team1.test → 10.7.21.150                     │
      │           │                                            │
      │           ▼ HTTPS/TCP 8443                             │
      │     Mac 2: nginx Edge + TLS + Round Robin              │
      │     10.7.21.150                                        │
      │           ├──────── HTTP/TCP 3001 ──→ Mac 3: Backend A │
      │           │                           10.7.16.120      │
      │           └──────── HTTP/TCP 3002 ──→ Mac 4: Backend B │
      │                                       10.7.5.29        │
      └────────────────────────────────────────────────────────┘
```

### Request Flow

```
Client (Mac 1 or Mac 4)
  │
  ├─ 1. DNS query to Mac 1 (10.3.3.225:53)
  │     → app.team1.test resolves to 10.7.21.150 (Mac 2)
  │
  ├─ 2. HTTPS connection to Mac 2 (10.7.21.150:8443)
  │     → TLS 1.2 handshake, certificate validated against local CA
  │
  ├─ 3. nginx reverse proxy on Mac 2
  │     → Terminates TLS, forwards HTTP to backend pool
  │
  └─ 4. Round-robin to one of:
        → Backend A on Mac 3 (10.7.16.120:3001) — X-Backend: A
        → Backend B on Mac 4 (10.7.5.29:3002)   — X-Backend: B
```

Both `app.team1.test` and `api.team1.test` resolve to Mac 2. Mac 2 terminates TLS and uses plain HTTP inside the private LAN to reach the backends. Clients never contact backends directly — they only know the edge domain.

---

## Machine / Service Table

| Machine | Role                  | IP Address      | Service         | Port  |
|---------|-----------------------|-----------------|-----------------|-------|
| Mac 1   | DNS Server + Client   | `10.3.3.225`    | dnsmasq         | 53    |
| Mac 2   | Edge / Reverse Proxy  | `10.7.21.150`   | nginx (HTTPS)   | 8443  |
| Mac 3   | Backend A             | `10.7.16.120`   | Python REST API | 3001  |
| Mac 4   | Backend B + Client    | `10.7.5.29`     | Python REST API | 3002  |

> **Note:** These IP addresses are from the current `settings.env` configurations. If the Wi-Fi network changes on demonstration day, update the `settings.env` files on each Mac and regenerate configs using the provided render scripts.

---

## Running the Backends

Both backends are pure Python 3 (standard library only — no `pip install` needed). Each backend reads its configuration from a `settings.env` file and binds to `0.0.0.0` so it is reachable over the LAN.

### Backend A — Mac 3

| Property               | Value                                              |
|-------------------------|----------------------------------------------------|
| **Source file**         | `Mac 3 - Backend A/backend_a.py`                   |
| **Start script**        | `Mac 3 - Backend A/start_backend_a.command`         |
| **Dependencies**        | Python 3 (pre-installed on macOS) — no pip packages |
| **Port**                | `3001`                                              |
| **Bind address**        | `0.0.0.0`                                           |
| **Health endpoint**     | `GET /api/status` → `{"backend":"A","status":"ok"}` |
| **X-Backend header**    | `A`                                                 |

```bash
# Option 1: Double-click the .command file
open "Mac 3 - Backend A/start_backend_a.command"

# Option 2: Run from Terminal
cd "Mac 3 - Backend A"
source ./settings.env
python3 backend_a.py
```

Verify it is running:

```bash
curl -i http://127.0.0.1:3001/api/status
# Expected: HTTP/1.1 200 OK
# X-Backend: A
# {"backend":"A","status":"ok"}
```

### Backend B — Mac 4

| Property               | Value                                              |
|-------------------------|----------------------------------------------------|
| **Source file**         | `Mac 4 - Backend B/backend_b.py`                   |
| **Start script**        | `Mac 4 - Backend B/start_backend_b.command`         |
| **Dependencies**        | Python 3 (pre-installed on macOS) — no pip packages |
| **Port**                | `3002`                                              |
| **Bind address**        | `0.0.0.0`                                           |
| **Health endpoint**     | `GET /api/status` → `{"backend":"B","status":"ok"}` |
| **X-Backend header**    | `B`                                                 |

```bash
# Option 1: Double-click the .command file
open "Mac 4 - Backend B/start_backend_b.command"

# Option 2: Run from Terminal
cd "Mac 4 - Backend B"
source ./settings.env
python3 backend_b.py
```

Verify it is running:

```bash
curl -i http://127.0.0.1:3002/api/status
# Expected: HTTP/1.1 200 OK
# X-Backend: B
# {"backend":"B","status":"ok"}
```

### API Endpoints (both backends)

| Method | Path          | Response (200)                                       | Notes                           |
|--------|---------------|------------------------------------------------------|---------------------------------|
| GET    | `/`           | `{"backend":"A/B","message":"...","service":"..."}` | Root info                       |
| GET    | `/api/status` | `{"backend":"A/B","status":"ok"}`                   | Health check                    |
| HEAD   | any           | Headers only, no body                                | Supports HEAD requests          |
| GET    | other paths   | `{"backend":"A/B","error":"Not Found"}` (404)       | —                               |

All responses include `Cache-Control: public, max-age=60`, `ETag`, and `X-Backend` headers. Conditional requests with `If-None-Match` return `304 Not Modified` when the ETag matches.

---

## Setting Up the DNS Server — Mac 1

1. Edit `Mac 1 - DNS/settings.env` — set `MAC1_IP` and `MAC2_IP` to the real LAN addresses.
2. Install dnsmasq: `brew install dnsmasq`
3. Generate the config: `python3 render_dns.py` (from the `Mac 1 - DNS/` directory)
4. Start: `./start_dns.command` (or double-click). Keep the Terminal open.
5. Verify: `dig @127.0.0.1 app.team1.test +short` → should return Mac 2's IP.
6. On Mac 2 and Mac 4, set DNS to Mac 1's IP in **System Settings → Network → Wi-Fi → Details → DNS**.

---

## Setting Up the Edge / Reverse Proxy — Mac 2

1. Edit `Mac 2 - Edge/settings.env` — set `MAC2_IP`, `MAC3_IP`, `MAC4_IP`.
2. Install nginx: `brew install nginx`
3. Generate the TLS certificate (once): `./create_certificate.command`
4. Generate nginx config: `python3 render_nginx.py`
5. Start: `./start_edge.command` (or double-click). Keep the Terminal open.
6. Share `certs/local-ca.crt` with client Macs and trust it in the System keychain.
7. **Never share** `local-ca.key` or `server.key`.

---

## Startup Order (Four-Mac Demo)

| Step | Machine | Action                                                                   |
|------|---------|--------------------------------------------------------------------------|
| 1    | All     | Connect all four Macs to the same private Wi-Fi. Fill `Shared/IP_INVENTORY.md`. Ping every pair. |
| 2    | Mac 3   | Edit `settings.env` if needed → run `start_backend_a.command`            |
| 3    | Mac 4   | Edit `settings.env` if needed → run `start_backend_b.command`            |
| 4    | Mac 2   | Edit `settings.env` → `brew install nginx` → `./create_certificate.command` → `./start_edge.command` |
| 5    | Mac 1   | Edit `settings.env` → `brew install dnsmasq` → `./start_dns.command`    |
| 6    | Mac 2, 4| Set DNS to Mac 1's IP. Trust `local-ca.crt` from Mac 2.                  |
| 7    | Client  | Run `Shared/verify_phase1.command` to validate the full flow.            |

Each `.command` file can be double-clicked in Finder or run from Terminal. Keep its Terminal window open while demonstrating. Press **Ctrl+C** to stop a service.

---

## Verification

### Quick End-to-End Test

From a client Mac with DNS configured and CA trusted:

```bash
# DNS resolution
dig app.team1.test +short
# Expected: 10.7.21.150

# HTTPS with certificate validation (no -k flag)
curl -I https://app.team1.test:8443/api/status

# Round-robin: run twice, observe X-Backend alternating A ↔ B
curl -s -I https://app.team1.test:8443/api/status | grep X-Backend
curl -s -I https://app.team1.test:8443/api/status | grep X-Backend

# Caching / Conditional 304
ETAG=$(curl -s -I https://app.team1.test:8443/api/status | grep -i etag | tr -d '\r' | awk '{print $2}')
curl -s -o /dev/null -w "%{http_code}" -H "If-None-Match: $ETAG" https://app.team1.test:8443/api/status
# Expected: 304
```

### Automated Verification Script

```bash
cd Shared
./verify_phase1.command
```

This script checks DNS, HTTPS certificate validation, A/B load balancing, cache headers, and conditional `304` responses.

---

## Wireshark Packet Analysis

Start a Wireshark capture on the client's active Wi-Fi interface **before** making requests.

**Display filter:** `dns or tcp.port == 8443`

Observable protocol layers:

| Layer         | Protocol     | What to look for                                              |
|---------------|-------------|---------------------------------------------------------------|
| Application   | DNS          | Query for `app.team1.test`, response with Mac 2's IP          |
| Transport     | UDP 53       | DNS query/response packets                                    |
| Transport     | TCP 8443     | SYN → SYN-ACK → ACK (three-way handshake)                    |
| Security      | TLS 1.2      | ClientHello, ServerHello, Certificate, ChangeCipherSpec, Finished |
| Application   | HTTPS        | Encrypted application data (viewable via `curl -v` or browser)|

On Mac 2, a separate capture with filter `tcp.port == 3001 or tcp.port == 3002` shows the HTTP connections to backends.

Save `.pcapng` captures in the `Evidence/` directory.

---

## Phase 1 Failure Scenarios

| # | Scenario                | What to do                                                       | Expected result                    |
|---|-------------------------|------------------------------------------------------------------|------------------------------------|
| 1 | Wrong client DNS        | Set client DNS to a different resolver                           | `dig app.team1.test` fails; `ping` to Mac 2 still works |
| 2 | Wrong DNS answer        | Change `MAC2_IP` in Mac 1 to an unused IP, restart DNS          | DNS resolves but HTTPS connection fails |
| 3 | One backend stopped     | Stop Backend A (Ctrl+C on Mac 3)                                | nginx routes all traffic to Backend B |
| 4 | Both backends stopped   | Stop both A and B                                                | DNS/TLS succeed; nginx returns `502 Bad Gateway` |
| 5 | Wrong destination port  | `curl -v --connect-timeout 3 https://app.team1.test:8444/`      | Host resolves but connection refused |

Restore original configuration after each failure test. Save evidence in `Evidence/`.

---

## Project Structure

```
CN_Project/
├── README.md                          ← This file
├── Mac 1 - DNS/
│   ├── README.md                      ← DNS setup instructions
│   ├── settings.env                   ← MAC1_IP, MAC2_IP, DOMAIN, UPSTREAM_DNS
│   ├── dnsmasq.conf                   ← Generated dnsmasq configuration
│   ├── render_dns.py                  ← Script to regenerate dnsmasq.conf from settings.env
│   └── start_dns.command              ← Start the DNS server
├── Mac 2 - Edge/
│   ├── README.md                      ← Edge/nginx setup instructions
│   ├── settings.env                   ← MAC2_IP, MAC3_IP, MAC4_IP, DOMAIN, HTTPS_PORT
│   ├── nginx.conf                     ← Generated nginx configuration
│   ├── render_nginx.py                ← Script to regenerate nginx.conf from settings.env
│   ├── create_certificate.command     ← Generate local CA + server TLS certificate
│   ├── start_edge.command             ← Start nginx
│   └── certs/                         ← TLS certificates and keys
├── Mac 3 - Backend A/
│   ├── README.md                      ← Backend A setup instructions
│   ├── settings.env                   ← BACKEND_HOST, BACKEND_PORT
│   ├── backend_a.py                   ← Python REST API server (port 3001)
│   └── start_backend_a.command        ← Start Backend A
├── Mac 4 - Backend B/
│   ├── README.md                      ← Backend B setup instructions
│   ├── settings.env                   ← BACKEND_HOST, BACKEND_PORT
│   ├── backend_b.py                   ← Python REST API server (port 3002)
│   └── start_backend_b.command        ← Start Backend B
├── Shared/
│   ├── IP_INVENTORY.md                ← LAN IP inventory (fill on demo day)
│   ├── TOPOLOGY.md                    ← Network topology diagram
│   ├── PHASE1_DEMO.md                 ← Detailed demonstration and evidence steps
│   ├── verify_phase1.command          ← Automated end-to-end verification script
│   ├── test_on_this_mac.command       ← One-laptop rehearsal test
│   ├── show_network.command           ← Show current Mac's network info
│   └── CN_Project_Doc.pdf             ← Project specification document
└── Evidence/
    └── README.md                      ← Instructions for saving demo evidence
```

---

## Technology Stack

| Component        | Technology                                    |
|------------------|-----------------------------------------------|
| DNS Server       | dnsmasq (via Homebrew)                        |
| Reverse Proxy    | nginx (via Homebrew) with TLS 1.2             |
| TLS Certificates | OpenSSL (self-signed local CA)                |
| Backends         | Python 3 `http.server` (standard library)     |
| Operating System | macOS                                         |
| Network          | Private Wi-Fi LAN                             |
| Packet Analysis  | Wireshark                                     |

---

## Configuration Reference

Each machine's `settings.env` controls its behavior. The key variables are:

| Variable        | File                          | Purpose                                       |
|-----------------|-------------------------------|-----------------------------------------------|
| `MAC1_IP`       | Mac 1 - DNS/settings.env      | DNS server listen address                     |
| `MAC2_IP`       | Mac 1 & Mac 2 settings.env    | Edge server IP (DNS answer + nginx listen)    |
| `MAC3_IP`       | Mac 2 - Edge/settings.env     | Backend A address for nginx upstream          |
| `MAC4_IP`       | Mac 2 - Edge/settings.env     | Backend B address for nginx upstream          |
| `DOMAIN`        | Mac 1 & Mac 2 settings.env    | Domain name (default: `team1.test`)           |
| `UPSTREAM_DNS`  | Mac 1 - DNS/settings.env      | Router/gateway DNS for non-`.test` queries    |
| `HTTPS_PORT`    | Mac 2 - Edge/settings.env     | HTTPS listen port (default: `8443`)           |
| `BACKEND_HOST`  | Mac 3 & Mac 4 settings.env    | Backend bind address (default: `0.0.0.0`)     |
| `BACKEND_PORT`  | Mac 3 & Mac 4 settings.env    | Backend listen port (`3001` / `3002`)         |

---

## License

This project was developed as a coursework submission for the Computer Networks course. It is intended for educational purposes only.
