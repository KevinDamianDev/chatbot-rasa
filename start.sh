#!/usr/bin/env bash
set -e

echo "🔌 Assigned PORT is: ${PORT}"

# 1) Arranca Rasa en background en el puerto 5005
rasa run \
  --enable-api \
  --cors "*" \
  --interface 0.0.0.0 \
  --port 5005 &

# 2) (Opcional) tu stub de healthcheck en background
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

# 3) Finalmente, arranca Nginx en primer plano usando tu nginx.conf
nginx -c /app/nginx.conf -g "daemon off;"