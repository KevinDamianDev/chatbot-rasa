FROM rasa/rasa:3.5.10-full

WORKDIR /app

# Copia solo lo esencial
COPY config.yml credentials.yml domain.yml endpoints.yml ./
COPY data ./data
COPY actions ./actions
COPY models/*.tar.gz ./models/

# Configuración crítica para Render
ENV RASA_ENVIRONMENT=production
ENV SANIC_HOST=0.0.0.0
ENV SANIC_WORKERS=1
EXPOSE 10000

# Healthcheck mejorado
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s \
  CMD curl -f http://localhost:10000 || exit 1

# Comando de inicio indestructible
ENTRYPOINT []
CMD ["sh", "-c", "rasa run --enable-api --cors '*' --port 10000 --debug"]