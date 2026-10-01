# Phase 1 network topology

Replace the `CHANGE` values in `IP_INVENTORY.md` with each laptop's LAN details before the demonstration. Current one-laptop rehearsal puts all roles at `10.7.7.233` on separate ports; the final topology uses four separate Macs on the same private Wi-Fi/LAN.

```text
                           Private Wi-Fi / LAN
      ┌────────────────────────────────────────────────────────┐
      │                                                        │
      │ Mac 1: DNS + client       Mac 4: Backend B + client    │
      │ DNS port 53               HTTP port 3002               │
      │     │ DNS query               │                         │
      │     └─────┐                   │                         │
      │           ▼                   │                         │
      │       app.team1.test -> Mac 2 IP                       │
      │           │                                             │
      │           ▼ HTTPS/TCP 8443                             │
      │     Mac 2: nginx edge + TLS + round robin              │
      │           ├──────── HTTP/TCP 3001 ──> Mac 3: Backend A │
      │           └──────── HTTP/TCP 3002 ──> Mac 4: Backend B │
      └────────────────────────────────────────────────────────┘
```

Both `app.team1.test` and `api.team1.test` are Mac 1 DNS records pointing to Mac 2. Browser/curl clients use the domain and validate Mac 2's certificate. nginx ends TLS and forwards HTTP to A or B. The response travels back through nginx to the client. DNS and HTTP are application layer; TCP and UDP are transport; IP is network; Wi-Fi/Ethernet is link. TLS secures the client-to-edge connection.

For the cloud comparison in the viva: Mac 1 is a managed DNS analogue, Mac 2 is a load-balancer/edge analogue, and Mac 3/4 are application instances. Everything here runs locally.
