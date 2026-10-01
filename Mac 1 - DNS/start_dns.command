#!/bin/zsh
set -e
cd "$(dirname "$0")"
python3 render_dns.py
DNSMASQ_BIN="$(command -v dnsmasq || true)"
if [[ -z "$DNSMASQ_BIN" && -x /opt/homebrew/sbin/dnsmasq ]]; then
  DNSMASQ_BIN=/opt/homebrew/sbin/dnsmasq
fi
if [[ -z "$DNSMASQ_BIN" && -x /usr/local/sbin/dnsmasq ]]; then
  DNSMASQ_BIN=/usr/local/sbin/dnsmasq
fi
if [[ -z "$DNSMASQ_BIN" ]]; then
  echo "Install dnsmasq first: brew install dnsmasq"
  exit 1
fi
echo "Mac 1 DNS will listen on port 53. macOS may ask for an administrator password."
sudo "$DNSMASQ_BIN" --no-daemon --conf-file="$PWD/dnsmasq.conf"
