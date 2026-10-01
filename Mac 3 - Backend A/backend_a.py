#!/usr/bin/env python3
"""Phase 1 Backend A: small LAN-accessible REST service on port 3001."""
import hashlib
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HOST = os.environ.get("BACKEND_HOST", "0.0.0.0")
PORT = int(os.environ.get("BACKEND_PORT", "3001"))


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server_version = "CN-Backend-A/1.0"

    def respond(self, send_body=True):
        path = self.path.split("?", 1)[0]
        if path == "/":
            status, data = 200, {"backend": "A", "message": "Backend A is running", "service": "Mac 3"}
        elif path == "/api/status":
            status, data = 200, {"backend": "A", "status": "ok"}
        else:
            status, data = 404, {"backend": "A", "error": "Not Found"}
        body = json.dumps(data, separators=(",", ":")).encode()
        etag = '"' + hashlib.sha256(body).hexdigest()[:16] + '"'
        if status == 200 and self.headers.get("If-None-Match") == etag:
            self.send_response(304)
            self.send_header("X-Backend", "A")
            self.send_header("Cache-Control", "public, max-age=60")
            self.send_header("ETag", etag)
            self.send_header("Content-Length", "0")
            self.end_headers()
            return
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("X-Backend", "A")
        self.send_header("Cache-Control", "public, max-age=60")
        self.send_header("ETag", etag)
        self.end_headers()
        if send_body:
            self.wfile.write(body)

    def do_GET(self):
        self.respond()

    def do_HEAD(self):
        self.respond(send_body=False)


if __name__ == "__main__":
    with ThreadingHTTPServer((HOST, PORT), Handler) as server:
        print(f"Mac 3 Backend A: http://{HOST}:{PORT} (Ctrl+C to stop)", flush=True)
        server.serve_forever()
