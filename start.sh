#!/usr/bin/env bash
set -e

echo "🔌 Assigned PORT is: ${PORT}"

# 1) Arranco nginx (que ya abrirá el puerto 10000 al instante)
nginx -c /app/nginx.conf

# 2) Ahora lanzo Rasa en background o en primer plano escuchando en 5005
#    Rasa no bloquea el puerto 10000, sino el 5005.
rasa run \
  --enable-api \
  --cors "*" \
  --interface 127.0.0.1 \
  --port 5005