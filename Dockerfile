FROM rasa/rasa:3.5.10-full

WORKDIR /app

# 1. Config y datos
COPY --chown=rasa:rasa \
  config.yml credentials.yml domain.yml endpoints.yml \
  ./
COPY --chown=rasa:rasa data    ./data
COPY --chown=rasa:rasa actions ./actions

# 2. Copia la carpeta de tu modelo (ya extraída localmente)
COPY --chown=rasa:rasa \
  models/20250501-095336-crispy-grain \
  /app/models/20250501-095336-crispy-grain

# 3. Renombra metadata.json → model_metadata.json para que Rasa lo detecte
RUN mv /app/models/20250501-095336-crispy-grain/metadata.json \
      /app/models/20250501-095336-crispy-grain/model_metadata.json

# 4. Entorno de Sanic/Rasa
ENV RASA_ENVIRONMENT=production \
    SANIC_HOST=0.0.0.0 \
    SANIC_PORT=10000 \
    SANIC_WORKERS=1 \
    PORT=10000         # para Render

# 5. Puerto + healthcheck
EXPOSE 10000
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:10000/webhooks/rest/webhook || exit 1

# 6. Ejecuta como rasa
USER rasa
ENTRYPOINT []

# 7. Arranque dejando que Rasa auto-detecte el único modelo en /app/models
CMD ["rasa", "run", "--enable-api", "--cors", "*", "--port", "10000", "--debug"]