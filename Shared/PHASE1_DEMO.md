# Phase 1 live demonstration and evidence

## Collect working evidence

1. **LAN:** show `IP_INVENTORY.md`; on each Mac run `ipconfig getifaddr en0`, `ifconfig en0`, and `route -n get default`. Ping every pair.
2. **DNS:** on two client Macs configured to use Mac 1 DNS, run `dig app.team1.test +short` and `dig @MAC1_IP app.team1.test +short`. Both should show the real Mac 2 IP. Also check `api.team1.test`.
3. **Backends:** on Mac 2, run `curl -i http://MAC3_IP:3001/api/status` and `curl -i http://MAC4_IP:3002/api/status`. See A and B.
4. **HTTPS:** on a client, open `https://app.team1.test:8443/` in browser, then run `curl -v https://app.team1.test:8443/api/status` (no `-k`). Inspect the certificate name and trusted local CA.
5. **Balancing and caching:** run `./verify_phase1.command` from this `Shared` folder. Save output showing A/B headers, `Cache-Control`, `ETag`, and a conditional `304`. Curl does not keep its own cache; the script explicitly sends `If-None-Match` to demonstrate validation.
6. **Packet flow:** start Wireshark capture on the client's active Wi-Fi interface. Display filter: `dns or tcp.port == 8443`. Start capture **before** DNS lookup. Run `dig @MAC1_IP app.team1.test`, then `curl --http1.1 -v https://app.team1.test:8443/`. Save `.pcapng` in `Evidence/`. The nginx config uses TLS 1.2 so you can identify DNS query/reply, TCP SYN/SYN-ACK/ACK, TLS ClientHello/ServerHello/Certificate/ChangeCipherSpec/Finished, then encrypted application data. Use `curl -v` or browser Network tab to show HTTP headers; the packet capture cannot show HTTPS payload without decryption.

The DNS query uses UDP 53 by default. HTTPS uses TCP 8443 (the PDF allows 8443 instead of 443). The client's source port is ephemeral; backends use 3001/3002. TLS ends at Mac 2. In a separate Mac 2 capture, `tcp.port == 3001 or tcp.port == 3002` shows its HTTP connection to backends.

## Phase 1 required failure scenarios (restore after each)

1. **Wrong client DNS:** temporarily set a client to another resolver and show that `dig app.team1.test` fails even though `ping MAC2_IP` works. Restore Mac 1 DNS.
2. **Wrong DNS answer:** temporarily change `MAC2_IP` in Mac 1 `settings.env` to an unused LAN IP, restart DNS and flush client cache (`sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`), then show lookup succeeds but HTTPS cannot reach the edge. Restore the real Mac 2 IP and restart DNS.
3. **One backend stopped:** stop Mac 3 Backend A with Control+C. Repeat HTTPS requests; nginx should use B. Start A again. This is the Phase 1 failure example, not the Phase 2 high-availability extension.
4. **Both backends stopped:** stop A and B. DNS/TLS may still succeed while nginx returns `502 Bad Gateway`. Restart both.
5. **Wrong destination port:** run `curl -v --connect-timeout 3 https://app.team1.test:8444/`; the host resolves, but that port has no HTTPS service.

Save screenshots/exports of each case in `Evidence/`. Record what changed and what was restored. If a failure result differs because of OS caching or another process on a port, explain the actual observation rather than inventing evidence.

## Short explanations for individual viva

- DNS maps `app.team1.test` to Mac 2's address. TCP connects the client to that address and port 8443. TLS validates the certificate and encrypts HTTPS. Nginx reads HTTP, selects A or B, and relays the response.
- A fresh cache hit reuses a response before max-age expires. A conditional request sends `If-None-Match` and may receive 304 with no body. A full new request returns 200 and a body.
- Nginx round robin sends successive uncached requests to both backend instances. The browser knows only the edge domain; it does not need backend addresses.
- HTTP/1.1 is demonstrated with `curl --http1.1`. HTTP/2 may be shown only if nginx is configured and supports it. HTTP/3 and email protocols are explanation-only here.
