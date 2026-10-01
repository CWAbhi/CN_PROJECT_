# Mac 4 — Backend B Upstream Service & Primary Demonstration Client

## Role Overview
- **Machine Dual Roles:**
  1. **Upstream Application Server:** Backend B serving JSON traffic on TCP port `3002`
  2. **Primary Demonstration Client:** Executes real client tests, DNS queries, HTTPS requests, and Wireshark packet captures
- **Configured IP:** `10.7.5.29`
- **Subnet:** `255.255.224.0` (/19) | Gateway: `10.7.0.1`
- **Listening Interface:** `0.0.0.0` (all interfaces, accessible across private LAN)
- **Listening Port:** TCP `3002`
- **Technology:** Python 3 standard library (`http.server.ThreadingHTTPServer`) — Zero external dependencies
- **Key Features:**
  - Serves JSON responses with identifying header `X-Backend: B`
  - Computes SHA-256 ETags for cache validation
  - Handles `If-None-Match` requests and returns `304 Not Modified`
  - Emits `Cache-Control: public, max-age=60` headers

---

## Part 1: Running Backend B Service

### 1. Verify `settings.env`
The local `settings.env` specifies the binding host and port:
```env
BACKEND_HOST=0.0.0.0
BACKEND_PORT=3002
```

### 2. Launch Backend B Service
Run the startup command:
```bash
cd "Mac 4 - Backend B"
./start_backend_b.command
# Or directly:
python3 backend_b.py
```
> Keep this terminal open. If macOS prompts to allow incoming network connections, click **Allow**.

### 3. Verify Local Service
```bash
curl -i http://127.0.0.1:3002/api/status
# Expected: HTTP/1.1 200 OK, {"backend":"B","status":"ok"}, X-Backend: B
```

---

## Part 2: Configuring Mac 4 as Test Client

Mac 4 serves as the main demonstration client in the project topology. It queries Mac 1 for DNS and connects securely to Mac 2 via HTTPS.

### 1. Configure DNS to Use Mac 1
1. Open **System Settings > Network > Wi-Fi > Details... > DNS**.
2. Click **+** and add Mac 1's IP: `10.3.3.225`.
3. (Optional) Temporarily remove other DNS servers to ensure strict resolution through Mac 1.
4. Click **OK** and **Apply**.
5. Test resolution in Terminal:
   ```bash
   dig app.team1.test +short
   # Must return Mac 2's IP: 10.7.21.150
   ```

### 2. Install & Trust Local CA Certificate
Copy `local-ca.crt` from `Mac 2 - Edge/certs/` to Mac 4:
```bash
# Add to System Keychain as trusted root CA:
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain local-ca.crt
```
*Alternatively: Double-click `local-ca.crt` in Finder, select System Keychain, open the certificate info, expand Trust, and select "Always Trust".*

---

## Part 3: End-to-End Client Demonstration Commands

Once DNS and the CA certificate are configured, run the following verification suite from Mac 4:

### 1. Verify DNS Query
```bash
dig app.team1.test
dig api.team1.test
```

### 2. Verify HTTPS Without `-k` (Insecure Flag)
```bash
curl -v https://app.team1.test:8443/
# Verify: TLS 1.3 handshake succeeds, certificate verified OK, 200 OK received
```

### 3. Verify Round-Robin Load Balancing
```bash
for i in {1..6}; do
  curl -s -i https://app.team1.test:8443/api/status | grep -E "HTTP/|X-Backend"
done
# Observe: alternating 'X-Backend: A' and 'X-Backend: B'
```

### 4. Verify Caching & 304 Not Modified
```bash
# Step A: Get initial response and save ETag
ETAG=$(curl -s -I https://app.team1.test:8443/api/status | grep -i ETag | tr -d '\r\n')
echo "Stored ETag: $ETAG"

# Step B: Send conditional request
curl -i -H "If-None-Match: $ETAG" https://app.team1.test:8443/api/status
# Observe: HTTP/1.1 304 Not Modified
```

---

## Part 4: Wireshark Packet Capture on Mac 4
Mac 4 is the ideal machine to record the complete graded packet capture:
1. Open Wireshark on Mac 4, select Wi-Fi interface (`en0`).
2. Filter: `(udp.port == 53) || (tcp.port == 8443)`
3. Start capture.
4. Execute:
   ```bash
   dig @10.3.3.225 app.team1.test
   curl https://app.team1.test:8443/api/status
   ```
5. Stop capture and save to `Evidence/10-Wireshark/full-client-flow.pcapng`.
