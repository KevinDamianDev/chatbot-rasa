#!/usr/bin/env bash
set -e

# Muestra el puerto asignado por Render
echo "🔌 Assigned PORT is: ${PORT}"

# Arranca Rasa escuchando en 0.0.0.0 y en el puerto que Render le pase
exec rasa run \
   --enable-api \
   --cors "*" \
   --interface 0.0.0.0 \
   --port "${PORT}"
