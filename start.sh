#!/usr/bin/env bash
set -e

echo "🔌 Assigned PORT is: ${PORT}"

# Levanta Rasa en foreground, directamente en el puerto que Render te asignó
exec rasa run \
  --enable-api \
  --cors "*" \
  --interface 0.0.0.0 \
  --port ${PORT}
