#!/usr/bin/env bash
set -e

echo "🔌 Assigned PORT is: ${PORT}"

# 1) Arranco nginx en background (usa tu nginx.conf)
nginx -c /app/nginx.conf &

# 2) Espero un par de segundos para que Nginx abra el puerto
sleep 2

# 3) Ahora lanzo Rasa en primer plano en el puerto interno (5005)
rasa run \
  --enable-api \
  --cors "*" \
  --interface 127.0.0.1 \
  --port 5005