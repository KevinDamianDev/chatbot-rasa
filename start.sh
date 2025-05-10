#!/usr/bin/env bash
set -e

echo "🔌 Assigned PORT is: ${PORT}"

# 1) Servidor ligero en Python en background:
python3 - <<'PYCODE' &
import os, socketserver, http.server

PORT = int(os.environ["PORT"])
class H(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"OK")

server = socketserver.TCPServer(("0.0.0.0", PORT), H)
server.serve_forever()
PYCODE

# 2) Ahora lanza Rasa como proceso principal
exec rasa run \
  --enable-api \
  --cors "*" \
  --interface 0.0.0.0 \
  --port $PORT