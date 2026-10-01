# Mac 3 — Backend A Upstream Application Service

## Role Overview
- **Machine Role:** Primary Upstream Application Server (Backend A)
- **Configured IP:** `10.7.7.233`
- **Listening Interface:** `0.0.0.0` (all interfaces, accessible across private LAN)
- **Listening Port:** TCP `3001`
- **Technology:** Python 3 standard library (`http.server.ThreadingHTTPServer`) — Zero external dependencies
- **Key Features:**
  - Serves JSON responses with identifying header `X-Backend: A`
  - Computes SHA-256 ETags for cache validation
  - Handles `If-None-Match` requests and returns `304 Not Modified`
  - Emits `Cache-Control: public, max-age=60` headers

---

## Prerequisites
- macOS with Python 3.x (macOS built-in `/usr/bin/python3` is completely sufficient; no `pip` or virtualenv needed).

---

## Step-by-Step Setup & Launch

### 1. Verify Network Interface
Ensure Mac 3 is connected to the same Wi-Fi network and check its IP address:
```bash
ifconfig en0 | grep "inet "
```
> **Important:** If the IP address has changed from `10.7.7.233`, update `MAC3_IP` in `Mac 2 - Edge/settings.env` and re-run `python3 render_nginx.py` on Mac 2.

### 2. Verify `settings.env`
The local `settings.env` specifies the binding host and port:
```env
BACKEND_HOST=0.0.0.0
BACKEND_PORT=3001
```

### 3. Launch Backend A Service
Run the startup command:
```bash
cd "Mac 3 - Backend A"
./start_backend_a.command
# Or directly:
python3 backend_a.py
```
> Keep this terminal window open during testing. If macOS prompts "Do you want the application to accept incoming network connections?", click **Allow**.

---

## Service Endpoints & Verification

### Local Verification on Mac 3
```bash
# Test root endpoint
curl -i http://127.0.0.1:3001/
# Response: 200 OK, {"backend":"A","message":"Backend A is running","service":"Mac 3"}

# Test API status endpoint
curl -i http://127.0.0.1:3001/api/status
# Response: 200 OK, {"backend":"A","status":"ok"}, X-Backend: A

# Test ETag caching (304 Not Modified)
ETAG=$(curl -s -I http://127.0.0.1:3001/api/status | grep -i ETag | tr -d '\r\n')
curl -i -H "If-None-Match: $ETAG" http://127.0.0.1:3001/api/status
# Response: HTTP/1.1 304 Not Modified
```

### Remote Verification from Mac 2 (Edge Proxy)
From Mac 2:
```bash
curl -i http://10.7.7.233:3001/api/status
```

---

## High Availability / Failure Testing Role
During the Phase 1 failover demonstration:
1. When instructed, press `Ctrl+C` in the terminal to simulate a hard service failure of Backend A.
2. The team will observe Mac 2 seamlessly redirecting 100% of client traffic to Backend B (Mac 4) with zero downtime.
3. Re-run `python3 backend_a.py` to restore Backend A and observe Nginx immediately resuming round-robin load balancing.

---

## Troubleshooting
- **`curl: (7) Failed to connect / No route to host`:**
  - Mac 3 Wi-Fi is disconnected, asleep, or on a different network.
  - Verify IP with `ipconfig getifaddr en0`.
- **`curl: (28) Connection timed out`:**
  - macOS Application Firewall is blocking incoming connections on port 3001. Go to `System Settings > Network > Firewall` and ensure incoming connections for Python are allowed.
