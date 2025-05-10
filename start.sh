#!/usr/bin/env bash
set -e

echo "🔌 Assigned PORT is: ${PORT}"

# Ejecuta Rasa como PID 1 y reemplaza este script inmediatamente,
# escuchando en 0.0.0.0:$PORT para que Render lo detecte.
exec rasa run \
  --enable-api \
  --cors "*" \
  --interface 0.0.0.0 \
  --port $PORT