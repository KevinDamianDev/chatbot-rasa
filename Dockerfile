# Stage 1: Entrena el modelo dentro de la imagen Rasa (en el build de Render)
FROM rasa/rasa:3.5.10-full AS builder

WORKDIR /app

# Copia configuración, datos y acciones
COPY --chown=rasa:rasa \
  config.yml credentials.yml domain.yml endpoints.yml \
  data/ actions/ \
  ./

# Entrena con la misma versión de Rasa/TensorFlow de producción
RUN rasa train --quiet


# Stage 2: Imagen final que sólo copia el modelo ya entrenado
FROM rasa/rasa:3.5.10-full

WORKDIR /app

# Copia configs, datos, acciones
COPY --chown=rasa:rasa \
  config.yml credentials.yml domain.yml endpoints.yml \
  data/ actions/ \
  ./

# Trae el modelo generado en el primer stage
COPY --from=builder /app/models /app/models

# Variables de entorno
ENV RASA_ENVIRONMENT=production \
    SANIC_WORKERS=1 \
    PORT=10000

# Exponer puerto
EXPOSE 10000

# Usa usuario rasa sin entrypoint heredado
USER rasa
ENTRYPOINT []

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3 \
  CMD curl -f http://localhost:10000/status || exit 1

# Arranca el servidor; Rasa detectará el modelo dentro de /app/models automáticamente
CMD ["rasa","run","--enable-api","--cors","*","-i","0.0.0.0","-p","10000"]
