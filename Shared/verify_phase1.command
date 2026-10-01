#!/bin/zsh
set -e
# CHANGE only if your team uses another domain or HTTPS port.
DOMAIN="${1:-team1.test}"
PORT="${2:-8443}"
HOSTNAME="app.$DOMAIN"
URL="https://$HOSTNAME:$PORT"
echo "DNS from this client's configured resolver:"
dig "$HOSTNAME" +short
echo "HTTPS and round robin (certificate validation enabled):"
for n in 1 2 3 4 5 6; do
  curl --silent --show-error --head --http1.1 "$URL/api/status" | tr -d '\r' | awk 'BEGIN {IGNORECASE=1} /^HTTP\/|^X-Backend:|^Cache-Control:|^ETag:/ {print}'
done
echo "Conditional request: capture an ETag, then look for HTTP 304 on the same backend."
ETAG="$(curl --silent --show-error --head --http1.1 "$URL/api/status" | tr -d '\r' | awk 'tolower($1)=="etag:" {print $2}')"
if [[ -n "$ETAG" ]]; then
  for n in 1 2 3 4; do
    curl --silent --show-error --head --http1.1 -H "If-None-Match: $ETAG" "$URL/api/status" | tr -d '\r' | awk 'BEGIN {IGNORECASE=1} /^HTTP\/|^X-Backend:|^Cache-Control:|^ETag:/ {print}'
  done
fi
