# Dockerfile optimizado: extrae el modelo en carpeta para evitar problemas de missing resources

FROM rasa/rasa:3.5.10-full

WORKDIR /app

# 1. Configuraciones y datos
COPY --chown=rasa:rasa \
  config.yml credentials.yml domain.yml endpoints.yml \
  ./
COPY --chown=rasa:rasa data       ./data
COPY --chown=rasa:rasa actions    ./actions

# 2. Copia el tar.gz y descomprímelo en un folder dentro de models/
COPY --chown=rasa:rasa \
  models/20250501-095336-crispy-grain.tar.gz \
  .

RUN mkdir -p /app/models/20250501-095336-crispy-grain \
 && tar -xzf 20250501-095336-crispy-grain.tar.gz \
       -C /app/models/20250501-095336-crispy-grain \
 && rm 20250501-095336-crispy-grain.tar.gz

# 3. Variables de entorno de Sanic / Rasa
ENV RASA_ENVIRONMENT=production \
    SANIC_HOST=0.0.0.0 \
    SANIC_PORT=10000 \
    SANIC_WORKERS=1

# 4. Exponer puerto y healthcheck
EXPOSE 10000
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:10000/webhooks/rest/webhook || exit 1

# 5. Arranca como usuario rasa
USER rasa
ENTRYPOINT []
CMD ["rasa", "run", "--enable-api", "--cors", "*", "--port", "10000", "--debug"]