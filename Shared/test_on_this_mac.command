#!/bin/zsh
# One-Mac Phase 1 rehearsal. Checks DNS on temporary port 1053 and HTTPS
# with explicit local DNS mapping; final four-Mac demo uses real DNS port 53.
set -u
cd "$(dirname "$0")" || exit 1
ROOT="$(cd .. && pwd)"
EDGE="$ROOT/Mac 2 - Edge"
DNS="$ROOT/Mac 1 - DNS"
CA="$EDGE/certs/local-ca.crt"
MAC2_IP="$(sed -n 's/^MAC2_IP=\([^ #]*\).*/\1/p' "$EDGE/settings.env")"
DOMAIN="$(sed -n 's/^DOMAIN=\([^ #]*\).*/\1/p' "$EDGE/settings.env")"
PORT="$(sed -n 's/^HTTPS_PORT=\([^ #]*\).*/\1/p' "$EDGE/settings.env")"
HOST="app.$DOMAIN"
URL="https://$HOST:$PORT"
failures=0

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }
request() {
  curl --noproxy '*' --silent --show-error --max-time 8 \
    --cacert "$CA" --resolve "$HOST:$PORT:$MAC2_IP" "$@" "$URL/api/status"
}

echo "Testing Phase 1 on this Mac: $MAC2_IP"
if [[ ! -f "$CA" ]]; then
  fail "CA certificate missing. Run Mac 2/create_certificate.command."
  exit 1
fi

if curl --noproxy '*' --silent --fail --max-time 3 http://127.0.0.1:3001/api/status | /usr/bin/grep -q '"backend":"A"'; then
  pass "Mac 3 Backend A (port 3001)"
else
  fail "Backend A. Run Mac 3 - Backend A/start_backend_a.command."
fi
if curl --noproxy '*' --silent --fail --max-time 3 http://127.0.0.1:3002/api/status | /usr/bin/grep -q '"backend":"B"'; then
  pass "Mac 4 Backend B (port 3002)"
else
  fail "Backend B. Run Mac 4 - Backend B/start_backend_b.command."
fi

# dnsmasq normally uses privileged port 53. A temporary 1053 test needs no sudo.
DNSMASQ_BIN="$(command -v dnsmasq || true)"
[[ -z "$DNSMASQ_BIN" && -x /opt/homebrew/sbin/dnsmasq ]] && DNSMASQ_BIN=/opt/homebrew/sbin/dnsmasq
if [[ -n "$DNSMASQ_BIN" ]]; then
  config_file="$(mktemp /tmp/cn-phase1-dns.XXXXXX)"
  sed -e 's/^port=53$/port=1053/' -e 's/^listen-address=.*/listen-address=127.0.0.1/' "$DNS/dnsmasq.conf" > "$config_file"
  "$DNSMASQ_BIN" --no-daemon --conf-file="$config_file" >/dev/null 2>&1 &
  dns_pid=$!
  sleep 1
  answer="$(dig @127.0.0.1 -p 1053 "$HOST" +short +time=1 +tries=1)"
  if [[ "$answer" == "$MAC2_IP" ]]; then
    pass "Mac 1 DNS maps $HOST to $MAC2_IP (temporary port 1053)"
  else
    fail "DNS expected $MAC2_IP, got '$answer'. Check Mac 1/settings.env."
  fi
  kill "$dns_pid" 2>/dev/null || true
  wait "$dns_pid" 2>/dev/null || true
  unlink "$config_file"
else
  fail "dnsmasq missing. Install with brew install dnsmasq."
fi

headers="$(request --head --http1.1 2>/dev/null)"
if [[ "$headers" == *"HTTP/1.1 200"* && "$headers" == *"Cache-Control:"* ]]; then
  pass "Mac 2 HTTPS/TLS and cache headers (port $PORT, CA verified)"
else
  fail "HTTPS edge. Run Mac 2 - Edge/start_edge.command."
fi

seen=""
for n in 1 2 3 4 5 6; do
  backend="$(request --head --http1.1 2>/dev/null | tr -d '\r' | sed -n 's/^X-Backend: \([AB]\).*/\1/p')"
  seen="$seen$backend"
done
if [[ "$seen" == *A* && "$seen" == *B* ]]; then
  pass "Load balancing across both backends: $seen"
else
  fail "Load balancing did not show both A and B: $seen"
fi

etag="$(print -r -- "$headers" | tr -d '\r' | sed -n 's/^ETag: \(.*\)/\1/p')"
not_modified=0
if [[ -n "$etag" ]]; then
  for n in 1 2 3 4; do
    conditional="$(request --head --http1.1 -H "If-None-Match: $etag" 2>/dev/null)"
    [[ "$conditional" == *"HTTP/1.1 304"* ]] && not_modified=1
  done
fi
if [[ "$not_modified" -eq 1 ]]; then
  pass "ETag conditional request returns HTTP 304"
else
  fail "ETag/304 caching check"
fi

if [[ "$failures" -eq 0 ]]; then
  echo "All one-Mac Phase 1 rehearsal checks passed."
else
  echo "$failures check(s) failed. Fix the named service and run this file again."
fi
exit "$failures"
