# Mac 2 — HTTPS Edge Reverse Proxy, TLS Termination & Load Balancer

## Role Overview
- **Machine Role:** Central Edge Reverse Proxy, TLS Terminator, and Upstream Load Balancer
- **Configured IP:** `10.7.21.150`
- **Subnet:** `255.255.224.0` (/19) | Gateway: `10.7.0.1` | MAC: `a2:b0:ad:72:36:e6`
- **Public Entry Point:** HTTPS on port `8443`
- **Domains Served:** `app.team1.test`, `api.team1.test`
- **Upstream Pool:**
  - Mac 3 (Backend A): `http://10.7.7.233:3001`
  - Mac 4 (Backend B): `http://10.7.5.29:3002`
- **Core Features:**
  - Valid TLS termination using private Local CA (`CN=CN Project Phase 1 Local CA`)
  - Round-robin load balancing across Backend A and Backend B
  - Micro-caching via `CN_CACHE` zone with conditional `304 Not Modified` / `ETag` pass-through
  - Health check failover (automatically bypasses offline backends)

---

## Prerequisites
Ensure Homebrew and Nginx are installed on Mac 2:
```bash
# 1. Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install Nginx
brew install nginx
```

---

## Step-by-Step Setup & Launch

### 1. Verify Configuration (`settings.env`)
Verify the physical IP entries in `settings.env`:
```env
MAC2_IP=10.7.21.150
MAC3_IP=10.7.7.233
MAC4_IP=10.7.5.29
DOMAIN=team1.test
HTTPS_PORT=8443
```

### 2. TLS Certificate Generation & Trust Distribution
The certificates are already created in `certs/`:
- `certs/local-ca.crt` (Root CA public certificate)
- `certs/server.crt` (Server certificate with SANs: `DNS:app.team1.test, DNS:api.team1.test`)
- `certs/server.key` (Server private key — kept secure on Mac 2)

**Distribute `certs/local-ca.crt` to all client Macs (Mac 1, Mac 4):**
On each client Mac (and Mac 2 if testing locally):
```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain certs/local-ca.crt
```
*Alternatively: Double-click `local-ca.crt` in Finder, add to System Keychain, and set Trust to "Always Trust".*

### 3. Generate `nginx.conf`
Generate the nginx configuration file:
```bash
cd "Mac 2 - Edge"
python3 render_nginx.py
```
> Note: Do not edit `nginx.conf` directly. Modify `settings.env` and re-run `render_nginx.py`.

### 4. Start Nginx Edge
Start the edge proxy service:
```bash
./start_edge.command
# Or directly:
nginx -p "$PWD" -c "$PWD/nginx.conf"
```
To verify it is listening:
```bash
lsof -nP -iTCP:8443 -sTCP:LISTEN
```
To stop or reload:
```bash
nginx -p "$PWD" -c "$PWD/nginx.conf" -s stop
nginx -p "$PWD" -c "$PWD/nginx.conf" -s reload
```

---

## Verification & Testing Suite

### 1. Preflight Backend Check
Ensure both upstream backends are responding before routing traffic through Nginx:
```bash
curl -i http://10.7.7.233:3001/api/status   # Backend A
curl -i http://10.7.5.29:3002/api/status   # Backend B
```

### 2. HTTPS & TLS Handshake Test
Test secure connection without `-k` (insecure flag):
```bash
curl -v --cacert certs/local-ca.crt https://app.team1.test:8443/
# Or if root CA is trusted in System Keychain:
curl -v https://app.team1.test:8443/
```

### 3. Load Balancing Verification
Run consecutive requests to observe `X-Backend` alternating between `A` and `B`:
```bash
for i in {1..6}; do
  curl -s -i --cacert certs/local-ca.crt https://app.team1.test:8443/api/status | grep -E "HTTP/|X-Backend"
done
```
*Expected: Alternate responses from Backend A and Backend B.*

### 4. Cache & 304 Not Modified Verification
Test caching and ETag revalidation:
```bash
# First request: fetches resource and returns ETag
ETAG=$(curl -s -I --cacert certs/local-ca.crt https://app.team1.test:8443/ | grep -i ETag | tr -d '\r\n')
echo "Received: $ETAG"

# Second request with If-None-Match header:
curl -i --cacert certs/local-ca.crt -H "If-None-Match: $ETAG" https://app.team1.test:8443/
# Expected: HTTP/1.1 304 Not Modified
```

### 5. High Availability & Failure Recovery Test
1. Stop Backend A on Mac 3 (`Ctrl+C`).
2. Run curl to edge: `curl -i https://app.team1.test:8443/api/status`
3. Observe: Nginx automatically routes 100% of requests to Backend B without returning 502/504 errors to the client.
4. Restart Backend A: Nginx automatically re-includes Backend A in the active pool.

---

## Wireshark Packet Capture Instructions
1. Filter on Mac 2: `tcp.port == 8443 or tcp.port == 3001 or tcp.port == 3002`
2. Perform an HTTPS request from a client machine.
3. Observe:
   - Client -> Mac 2: TLS Client Hello, Server Hello, Key Exchange, Encrypted Application Data.
   - Mac 2 -> Backend A/B: Plaintext HTTP GET over LAN on port 3001/3002.
   - Backend A/B -> Mac 2: Plaintext HTTP 200 OK with `X-Backend` header.
   - Mac 2 -> Client: Encrypted TLS Application Data.
