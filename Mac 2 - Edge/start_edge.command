#!/bin/zsh
set -e
cd "$(dirname "$0")"
python3 render_nginx.py
NGINX_BIN="$(command -v nginx || true)"
if [[ -z "$NGINX_BIN" ]]; then
  echo "Install nginx first: brew install nginx"
  exit 1
fi
if [[ ! -f certs/server.crt || ! -f certs/server.key ]]; then
  echo "Run ./create_certificate.command first."
  exit 1
fi
"$NGINX_BIN" -t -p "$PWD/" -c "$PWD/nginx.conf"
"$NGINX_BIN" -p "$PWD/" -c "$PWD/nginx.conf" -g 'daemon off;'
