# 1. Base image
FROM rasa/rasa:3.5.10-full

# 2. Directorio de trabajo
WORKDIR /app

# 3. Copia configuración, datos y acciones
COPY --chown=rasa:rasa \
  config.yml credentials.yml domain.yml endpoints.yml \
  ./
COPY --chown=rasa:rasa \
  data/ ./data
COPY --chown=rasa:rasa \
  actions/ ./actions

# 4. Prepara carpeta de modelos y copia el tar.gz parcheado (ya sin “-patched”)
RUN mkdir -p /app/models
COPY --chown=rasa:rasa \
  models/20250501-095336-crispy-grain.tar.gz \
  /app/models/20250501-095336-crispy-grain.tar.gz

# 5. Variables de entorno para Rasa/Sanic y Render
ENV RASA_ENVIRONMENT=production \
    SANIC_HOST=0.0.0.0 \
    SANIC_PORT=10000 \
    SANIC_WORKERS=1 \
    PORT=10000

# 6. Exponer puerto y healthcheck
EXPOSE 10000
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:10000/webhooks/rest/webhook || exit 1

# 7. Ejecuta como usuario rasa
USER rasa
ENTRYPOINT []

# 8. Arranque forzando la carga del modelo TAR.gz
CMD ["rasa", "run", \
     "--model", "/app/models/20250501-095336-crispy-grain.tar.gz", \
     "--enable-api", "--cors", "*", \
     "--port", "10000", "--debug"]