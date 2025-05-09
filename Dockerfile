# syntax=docker/dockerfile:1
FROM rasa/rasa:3.5.10-full AS base

WORKDIR /app

# Copiamos sólo lo imprescindible
COPY config.yml        .
COPY credentials.yml   .
COPY domain.yml        .
COPY endpoints.yml     .
COPY data/             ./data
COPY actions/          ./actions
COPY models/           ./models

# Exponemos el puerto que Render usará
EXPOSE 10000

# Arrancamos Rasa escuchando en $PORT (10000 por defecto en Render)
CMD ["rasa","run","--enable-api","--cors","*","--debug","--interface","0.0.0.0","--port","$PORT"]