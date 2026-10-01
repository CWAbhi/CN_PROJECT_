#!/usr/bin/env python3
"""Render Mac 1's dnsmasq configuration from settings.env."""
from pathlib import Path
import ipaddress

ROOT = Path(__file__).resolve().parent
values = {}
for raw in (ROOT / "settings.env").read_text().splitlines():
    line = raw.split("#", 1)[0].strip()
    if line and "=" in line:
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip()

for key in ("MAC1_IP", "MAC2_IP", "UPSTREAM_DNS"):
    ipaddress.IPv4Address(values[key])
domain = values["DOMAIN"]
if not domain.endswith(".test") or any(c not in "abcdefghijklmnopqrstuvwxyz0123456789-." for c in domain):
    raise SystemExit("DOMAIN must be a safe .test name")

config = f"""# Generated from settings.env. Edit settings.env, then rerun render_dns.py.
# CHANGE MAC1_IP and MAC2_IP in settings.env when using separate Macs.
port=53
listen-address=127.0.0.1,{values['MAC1_IP']}
bind-interfaces
no-resolv
server={values['UPSTREAM_DNS']}
domain-needed
local=/{domain}/
address=/app.{domain}/{values['MAC2_IP']}
address=/api.{domain}/{values['MAC2_IP']}
log-queries
log-facility=-
"""
target = ROOT / "dnsmasq.conf"
target.write_text(config)
print(f"Wrote {target}")
