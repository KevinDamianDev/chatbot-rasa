#!/usr/bin/env bash
set -e

echo "🔌 Assigned PORT is: ${PORT}"

# 1) Levanta Rasa en background en el puerto interno 5005
rasa run \
  --model /app/models \
  --enable-api \
  --cors "*" \
  --port 5005 \
  --interface 0.0.0.0 &

# 2) Levanta nginx en primer plano con tu config
nginx -c /app/nginx.conf -g 'daemon off;'