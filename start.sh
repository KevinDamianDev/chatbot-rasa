#!/usr/bin/env bash
set -e

echo "🔌 Assigned PORT is: ${PORT}"

# 1) Levanta Rasa en background escuchando en 5005
rasa run \
  --enable-api \
  --cors "*" \
  --interface 0.0.0.0 \
  --port 5005 &

# 2) Dale un par de segundos a Rasa para que termine de arrancar
sleep 5

# 3) Arranca Nginx usando tu configuración, en foreground
nginx -c /app/nginx.conf -g 'daemon off;'