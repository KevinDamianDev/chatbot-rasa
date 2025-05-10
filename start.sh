#!/usr/bin/env bash
set -e

echo "🔌 Assigned PORT is: ${PORT}"

exec rasa run \
  --enable-api \
  --cors "*" \
  --interface 0.0.0.0 \
  --port $PORT
