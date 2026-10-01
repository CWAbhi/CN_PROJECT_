# Computer Networks Project — Phase 1 Evidence Ledger & Verification Matrix

This directory contains real test logs, packet captures, and authentic VS Code terminal screenshots demonstrating complete compliance with all Phase 1 project requirements.

**Policy: Zero fabricated evidence.** All outputs and captures are produced by live execution of the services and network tools.

---

## Complete Phase 1 Verification Matrix (All Passing)

| Category | Text Log File | VS Code Terminal Screenshot | Physical Test Performed | Result | Details |
|---|---|---|---|---|---|
| **01-LAN** | [`mac2-network-info.txt`](01-LAN/mac2-network-info.txt) | [`01_mac2_network_info.png`](01-LAN/01_mac2_network_info.png) | Interface `en0`, DHCP lease, IP, Subnet, Gateway, MAC | **PASS** | `10.7.21.150/19`, GW `10.7.0.1`, MAC `a2:b0:ad:72:36:e6` |
| **02-Ping** | [`mac2-to-mac1.txt`](02-Ping/mac2-to-mac1.txt) | [`02_ping_mac1_dns.png`](02-Ping/02_ping_mac1_dns.png) | ICMP Echo Request to Mac 1 (`10.3.3.225`) | **PASS** | 3 pkts, 0% loss, avg 64.1ms RTT |
| **02-Ping** | [`mac2-to-mac3.txt`](02-Ping/mac2-to-mac3.txt) | [`03_ping_mac3_backend_a.png`](02-Ping/03_ping_mac3_backend_a.png) | ICMP Echo Request to Mac 3 (`10.7.16.120`) | **PASS** | 4 pkts, 0% loss, avg 23.6ms RTT (Updated IP) |
| **02-Ping** | [`mac2-to-mac4.txt`](02-Ping/mac2-to-mac4.txt) | [`04_ping_mac4_backend_b.png`](02-Ping/04_ping_mac4_backend_b.png) | ICMP Echo Request to Mac 4 (`10.7.5.29`) | **PASS** | 3 pkts, 0% loss, avg 249ms RTT |
| **03-DNS** | [`01_dnsmasq_resolution.txt`](03-DNS/01_dnsmasq_resolution.txt) | [`05_dns_query_mac1.png`](03-DNS/05_dns_query_mac1.png) | Authoritative DNS resolution for `team1.test` | **PASS** | `app.team1.test` & `api.team1.test` -> `10.7.21.150` |
| **04-Backend-A**| [`01_backend_a_service.txt`](04-Backend-A/01_backend_a_service.txt) | [`06_backend_a_curl.png`](04-Backend-A/06_backend_a_curl.png) | Upstream Backend A JSON API & `X-Backend: A` header | **PASS** | Port 3001 returns 200 OK, SHA-256 ETag generated |
| **05-Backend-B**| [`01_backend_b_service.txt`](05-Backend-B/01_backend_b_service.txt) | [`07_backend_b_curl.png`](05-Backend-B/07_backend_b_curl.png) | Upstream Backend B JSON API & `X-Backend: B` header | **PASS** | Port 3002 returns 200 OK, SHA-256 ETag generated |
| **06-Nginx** | [`01_nginx_edge_service.txt`](06-Nginx/01_nginx_edge_service.txt) | [`08_nginx_config_render.png`](06-Nginx/08_nginx_config_render.png) | Nginx 1.31.6 configuration syntax test & listener | **PASS** | Syntax OK, listening on `10.7.21.150:8443` |
| **07-HTTPS-TLS**| [`mac2-certificate-verification.txt`](07-HTTPS-TLS/mac2-certificate-verification.txt) | [`09_tls_cert_verify.png`](07-HTTPS-TLS/09_tls_cert_verify.png) | OpenSSL cert chain, SAN, and validity check | **PASS** | Chain OK, SANs: `app.team1.test, api.team1.test` |
| **08-Load-Balancing**| [`01_round_robin_evidence.txt`](08-Load-Balancing/01_round_robin_evidence.txt) | [`10_load_balancing_alternation.png`](08-Load-Balancing/10_load_balancing_alternation.png) | 6 consecutive requests through Edge Proxy | **PASS** | Strict alternation: A -> B -> A -> B -> A -> B |
| **09-Caching** | [`01_cache_304_evidence.txt`](09-Caching/01_cache_304_evidence.txt) | [`11_caching_304_not_modified.png`](09-Caching/11_caching_304_not_modified.png) | Conditional request with `If-None-Match` | **PASS** | HTTP/1.1 304 Not Modified, 0 bytes body |
| **10-Wireshark**| [`01_wireshark_packet_summary.txt`](10-Wireshark/01_wireshark_packet_summary.txt) | [`12_wireshark_packet_capture.png`](10-Wireshark/12_wireshark_packet_capture.png) | Real `.pcap` capture of 196 packets | **PASS** | [`dns-tls-loadbalancing.pcap`](10-Wireshark/dns-tls-loadbalancing.pcap) (DNS + TLS + HTTP) |
| **11-Failure-Cases**| [`01_backend_failover_recovery.txt`](11-Failure-Cases/01_backend_failover_recovery.txt) | [`13_failover_recovery_test.png`](11-Failure-Cases/13_failover_recovery_test.png) | Backend A crash failover to B & automatic recovery | **PASS** | 0% downtime/errors during outage; auto rebalanced |
| **FINAL Audit**| [`Shared/LOCAL_REHEARSAL_RESULTS.md`](../Shared/LOCAL_REHEARSAL_RESULTS.md) | [`14_full_verification_pass_matrix.png`](FINAL/14_full_verification_pass_matrix.png) | Full test suite execution via `test_on_this_mac.command` | **PASS** | All Phase 1 requirements confirmed passing |

---

## Packet Capture Artifact
The Wireshark capture file is located at:
`Evidence/10-Wireshark/dns-tls-loadbalancing.pcap`
This file contains the complete live sequence of:
1. UDP port 1053/53 DNS query & response.
2. TCP 3-way handshake on port 8443.
3. TLS 1.2 Handshake (Client Hello, Server Hello, Certificate, Key Exchange).
4. Plaintext HTTP upstream forwarding on port 3001/3002.
5. TLS Application Data encrypted response to client.
