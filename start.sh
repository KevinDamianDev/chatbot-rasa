#!/usr/bin/env bash
set -e

echo "🔌 Assigned PORT is: ${PORT}"

# 1) Rasa en background
rasa run \
  --enable-api \
  --cors "*" \
  --interface 0.0.0.0 \
  --port 5005 &

# 2) Nginx en foreground
nginx -c /app/nginx.conf -g "daemon off;"
