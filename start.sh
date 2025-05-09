#!/usr/bin/env bash
set -e

echo "🔌 Assigned PORT is: ${PORT}"

# Este es el comando real que arranca Rasa
rasa run \
  --enable-api \
  --cors "*" \
  --debug \
  --interface 0.0.0.0 \
  --port $PORT