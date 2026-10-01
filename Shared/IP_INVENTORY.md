# Phase 1 LAN Inventory (Physical 4-Mac Setup)

Updated for the live physical demonstration network.

| Role | Device / Hostname | Private IPv4 | Subnet/prefix | Gateway | Active interface | Hardware MAC Address | Service & Port | Status |
|---|---|---|---|---|---|---|---|---|
| **Mac 1** | DNS Server / Client | `10.3.3.225` | `255.255.224.0` (/19) | `10.7.0.1` | `en0` (Wi-Fi) | Confirmed via ARP/Ping | DNS 53 UDP/TCP | Reachable (Ping: ~62ms) |
| **Mac 2** | Edge / Reverse Proxy / TLS | `10.7.21.150` | `255.255.224.0` (/19) | `10.7.0.1` | `en0` (Wi-Fi) | `a2:b0:ad:72:36:e6` | HTTPS 8443 TCP | Local Machine |
| **Mac 3** | Backend A | `10.7.16.120` | `255.255.224.0` (/19) | `10.7.0.1` | `en0` (Wi-Fi) | Confirmed via ARP/Ping | HTTP 3001 TCP | Reachable (Ping: ~23ms) |
| **Mac 4** | Backend B / Client | `10.7.5.29` | `255.255.224.0` (/19) | `10.7.0.1` | `en0` (Wi-Fi) | Confirmed via ARP/Ping | HTTP 3002 TCP | Reachable (Ping: ~250ms) |

---

## Network Architecture Notes

- **All 4 Physical Macs are confirmed on the network and reachable via ICMP ping!**
- **Default Gateway:** `10.7.0.1`
- **Domain:** `team1.test`
- **DNS Records:**
  - `app.team1.test` -> `10.7.21.150` (Mac 2)
  - `api.team1.test` -> `10.7.21.150` (Mac 2)
- **Edge Reverse Proxy:** Mac 2 terminates TLS (port 8443) and load balances between Mac 3 (`10.7.16.120:3001`) and Mac 4 (`10.7.5.29:3002`).
- **Client Access:** Clients only ever communicate directly with Mac 1 (DNS 53) and Mac 2 (HTTPS 8443). Mac 3 and Mac 4 are isolated upstream services.
