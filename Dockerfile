FROM rasa/rasa:3.5.10-full

WORKDIR /app

# Copia los archivos esenciales
COPY config.yml credentials.yml domain.yml endpoints.yml ./
COPY data ./data
COPY actions ./actions
COPY models/*.tar.gz ./models/

# Configuración crítica para Render
ENV RASA_ENVIRONMENT=production
ENV SANIC_HOST=0.0.0.0
ENV SANIC_PORT=10000
ENV SANIC_WORKERS=1
EXPOSE 10000

# Healthcheck mejorado (usando un endpoint que siempre existe)
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s \
  CMD curl -f http://localhost:10000/webhooks/rest/webhook || exit 1

# Comando de inicio optimizado
ENTRYPOINT []
CMD ["sh", "-c", "rasa run --enable-api --cors '*' --port $SANIC_PORT --debug"]