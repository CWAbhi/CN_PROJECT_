#!/usr/bin/env python3
"""Render a standalone nginx config inside this folder."""
from pathlib import Path
import ipaddress

ROOT = Path(__file__).resolve().parent
values = {}
for raw in (ROOT / "settings.env").read_text().splitlines():
    line = raw.split("#", 1)[0].strip()
    if line and "=" in line:
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip()
for key in ("MAC2_IP", "MAC3_IP", "MAC4_IP"):
    ipaddress.IPv4Address(values[key])
domain = values["DOMAIN"]
if not domain.endswith(".test") or any(c not in "abcdefghijklmnopqrstuvwxyz0123456789-." for c in domain):
    raise SystemExit("DOMAIN must be a safe .test name")
port = int(values["HTTPS_PORT"])
if not 1 <= port <= 65535:
    raise SystemExit("HTTPS_PORT must be valid")

config = f"""# Generated from settings.env. Edit settings.env and rerun render_nginx.py.
# CHANGE Mac 2/3/4 IPs in settings.env when using separate laptops.
worker_processes 1;
pid "{ROOT / 'nginx.pid'}";
error_log "{ROOT / 'nginx-error.log'}" info;
events {{ worker_connections 256; }}
http {{
    access_log "{ROOT / 'nginx-access.log'}";
    upstream backend_pool {{
        # Mac 3 Backend A, then Mac 4 Backend B; nginx uses round robin.
        server {values['MAC3_IP']}:3001 max_fails=1 fail_timeout=5s;
        server {values['MAC4_IP']}:3002 max_fails=1 fail_timeout=5s;
    }}
    server {{
        listen {values['MAC2_IP']}:{port} ssl;
        server_name app.{domain} api.{domain};
        ssl_certificate "{ROOT / 'certs' / 'server.crt'}";
        ssl_certificate_key "{ROOT / 'certs' / 'server.key'}";
        # Phase 1 packet capture: TLS 1.2 shows certificate and ChangeCipherSpec.
        ssl_protocols TLSv1.2;
        location / {{
            proxy_pass http://backend_pool;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;
            proxy_next_upstream error timeout http_502 http_503 http_504;
            proxy_next_upstream_tries 2;
            proxy_connect_timeout 3s;
            proxy_read_timeout 10s;
        }}
    }}
}}
"""
target = ROOT / "nginx.conf"
target.write_text(config)
print(f"Wrote {target}")
