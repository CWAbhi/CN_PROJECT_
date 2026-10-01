# Phase 1 Test & Verification Results (Mac 2 — 10.7.21.150)

This records the comprehensive Phase 1 test suite executed and verified passing on this machine (`10.7.21.150`).

| Phase 1 Requirement | Test Description | Command Executed | Result | Evidence File / Terminal Image |
|---|---|---|---|---|
| **01. LAN Identification** | Interface `en0`, DHCP lease, IP, Subnet, Gateway, MAC | `ifconfig en0 && route -n get default` | **PASS** | [`Evidence/01-LAN/01_mac2_network_info.png`](../Evidence/01-LAN/01_mac2_network_info.png) |
| **02. ICMP LAN Ping** | 4-node LAN reachability (Mac 1, Mac 3, Mac 4) | `ping -c 3 <IP>` | **PASS** | [`Evidence/02-Ping/02_ping_mac1_dns.png`](../Evidence/02-Ping/02_ping_mac1_dns.png) |
| **03. Private Authoritative DNS** | `app.team1.test` & `api.team1.test` resolve to Edge IP | `dig @127.0.0.1 -p 1053 app.team1.test` | **PASS** | [`Evidence/03-DNS/05_dns_query_mac1.png`](../Evidence/03-DNS/05_dns_query_mac1.png) |
| **04. Upstream Backend A** | JSON API service on port 3001, `X-Backend: A` | `curl -i http://127.0.0.1:3001/api/status` | **PASS** | [`Evidence/04-Backend-A/06_backend_a_curl.png`](../Evidence/04-Backend-A/06_backend_a_curl.png) |
| **05. Upstream Backend B** | JSON API service on port 3002, `X-Backend: B` | `curl -i http://127.0.0.1:3002/api/status` | **PASS** | [`Evidence/05-Backend-B/07_backend_b_curl.png`](../Evidence/05-Backend-B/07_backend_b_curl.png) |
| **06. Nginx Edge Proxy** | Nginx 1.31.6 configuration syntax & port 8443 listener | `nginx -t && lsof -iTCP:8443` | **PASS** | [`Evidence/06-Nginx/08_nginx_config_render.png`](../Evidence/06-Nginx/08_nginx_config_render.png) |
| **07. HTTPS & TLS Handshake** | Valid private CA verification, SAN matching, TLS 1.2 | `openssl verify -CAfile certs/local-ca.crt ...` | **PASS** | [`Evidence/07-HTTPS-TLS/09_tls_cert_verify.png`](../Evidence/07-HTTPS-TLS/09_tls_cert_verify.png) |
| **08. Load Balancing** | 6 consecutive requests strictly alternating A and B | `for n in {1..6}; do curl ...; done` | **PASS** | [`Evidence/08-Load-Balancing/10_load_balancing_alternation.png`](../Evidence/08-Load-Balancing/10_load_balancing_alternation.png) |
| **09. Caching & 304 Validation** | `If-None-Match` revalidation returns HTTP 304 | `curl -i -H "If-None-Match: $ETAG" ...` | **PASS** | [`Evidence/09-Caching/11_caching_304_not_modified.png`](../Evidence/09-Caching/11_caching_304_not_modified.png) |
| **10. Wireshark Packet Capture** | Real `.pcap` recording DNS, TCP, TLS, and HTTP flows | `tcpdump -i lo0 -w Evidence/10-Wireshark/...` | **PASS** | [`Evidence/10-Wireshark/12_wireshark_packet_capture.png`](../Evidence/10-Wireshark/12_wireshark_packet_capture.png) |
| **11. High Availability Failover**| Hard crash of Backend A automatically routes to B | `kill <pid>` then `curl` | **PASS** | [`Evidence/11-Failure-Cases/13_failover_recovery_test.png`](../Evidence/11-Failure-Cases/13_failover_recovery_test.png) |

---

## Complete Verification Script Status

The master verification script (`Shared/test_on_this_mac.command`) was executed and confirms all requirements pass:
```
Testing Phase 1 on this Mac: 10.7.21.150
PASS: Mac 3 Backend A (port 3001)
PASS: Mac 4 Backend B (port 3002)
PASS: Mac 1 DNS maps app.team1.test to 10.7.21.150 (port 1053)
PASS: Mac 2 HTTPS/TLS and cache headers (port 8443, CA verified)
PASS: Load balancing across both backends: ABABAB
PASS: ETag conditional request returns HTTP 304
All Phase 1 requirements confirmed and passing!
```
Visual confirmation saved at: [`Evidence/FINAL/14_full_verification_pass_matrix.png`](../Evidence/FINAL/14_full_verification_pass_matrix.png).
