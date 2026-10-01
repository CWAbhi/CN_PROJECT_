# Mac 1 — Authoritative Private DNS Server & Test Client

## Role Overview
- **Machine Role:** Authoritative DNS Server for the `.test` private domain + Diagnostic Test Client
- **Configured IP:** `10.3.3.225`
- **Subnet:** `255.255.224.0` (/19) | Gateway: `10.7.0.1`
- **Listening Port:** UDP/TCP port `53`
- **Resolves:**
  - `app.team1.test` -> `10.7.21.150` (Mac 2 Edge)
  - `api.team1.test` -> `10.7.21.150` (Mac 2 Edge)
- **Upstream Forwarding:** Forwards non-local DNS queries to router gateway `10.7.0.1`

---

## Prerequisites
Ensure Homebrew and `dnsmasq` are installed on Mac 1:
```bash
brew install dnsmasq
```

---

## Step-by-Step Setup & Launch

### 1. Verify Configuration (`settings.env`)
Verify the entries in `settings.env`:
```env
MAC1_IP=10.3.3.225
MAC2_IP=10.7.21.150
DOMAIN=team1.test
UPSTREAM_DNS=10.7.0.1
```

### 2. Generate `dnsmasq.conf`
Generate the active configuration from `settings.env`:
```bash
cd "Mac 1 - DNS"
python3 render_dns.py
```
This writes `dnsmasq.conf` mapping `app.team1.test` and `api.team1.test` to `10.7.21.150`.

### 3. Start `dnsmasq`
Run the start script (requires `sudo` for port 53 binding):
```bash
sudo ./start_dns.command
# Or directly:
sudo dnsmasq -C dnsmasq.conf -d
```
> Keep this terminal window open during testing.

---

## Verification & Testing

### Local Test on Mac 1
```bash
# Query local loopback
dig @127.0.0.1 app.team1.test +short
# Expected output: 10.7.21.150

dig @127.0.0.1 api.team1.test +short
# Expected output: 10.7.21.150

# Test upstream forwarding (e.g. google.com)
dig @127.0.0.1 google.com +short
```

### Remote Verification from Client Macs (Mac 2, Mac 3, Mac 4)
From any other Mac on the network:
```bash
dig @10.3.3.225 app.team1.test +short
# Expected: 10.7.21.150
```

---

## Wireshark Packet Capture Instructions
To capture DNS traffic for graded evidence:
1. Open Wireshark on Mac 1 or Mac 4 (client).
2. Select active interface (`en0` / Wi-Fi).
3. Set capture filter: `port 53`
4. Send test query: `dig @10.3.3.225 app.team1.test`
5. Observe and verify:
   - Standard query `A app.team1.test` from Client to `10.3.3.225:53`
   - Standard query response `A 10.7.21.150` from `10.3.3.225:53` to Client
6. Save capture as `Evidence/10-Wireshark/01-dns-resolution.pcapng`.

---

## Troubleshooting
- **Permission denied (port 53):** Port 53 is a privileged port; `sudo` is strictly required.
- **Address already in use:** Another DNS daemon (e.g., mDNSResponder or prior dnsmasq) is running. Check with `sudo lsof -i :53` and stop conflicting services.
- **Connection timed out from remote Macs:** Ensure macOS Firewall is allowing incoming connections (`System Settings > Network > Firewall`).
