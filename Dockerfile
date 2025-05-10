FROM rasa/rasa:3.5.10-full

WORKDIR /app

# 1. Copia primero las configuraciones
COPY config.yml credentials.yml domain.yml endpoints.yml ./
COPY data ./data
COPY actions ./actions

# 2. Copia el modelo específico (evita wildcards)
COPY models/20250501-095336-crispy-grain.tar.gz ./models/

# 3. Configuración de entorno crítica
ENV RASA_ENVIRONMENT=production
ENV SANIC_HOST=0.0.0.0
ENV SANIC_PORT=10000
ENV SANIC_WORKERS=1
EXPOSE 10000

# 4. Healthcheck con retry
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:10000/webhooks/rest/webhook || exit 1

# 5. Permisos y usuario
RUN chown -R rasa:rasa /app
USER rasa

# 6. Comando optimizado
ENTRYPOINT []
CMD ["rasa", "run", "--enable-api", "--cors", "*", "--port", "10000", "--debug"]