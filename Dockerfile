FROM rasa/rasa:3.5.10-full

WORKDIR /app

# Copia selectiva de archivos
COPY config.yml credentials.yml domain.yml endpoints.yml ./
COPY data ./data
COPY actions ./actions
COPY models/*.tar.gz ./models/  # Asegúrate de tener solo UN modelo

# Configuración crítica
ENV RASA_ENVIRONMENT=production
ENV SANIC_HOST=0.0.0.0
ENV SANIC_WORKERS=1
EXPOSE 10000

# Healthcheck mejorado
HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl -f http://localhost:10000/webhooks/rest/webhook || exit 1

# Comando de inicio indestructible
USER rasa
ENTRYPOINT []
CMD ["rasa", "run", "--enable-api", "--cors", "*", "--port", "10000"]