# 1. Base image oficial de Rasa
FROM rasa/rasa:3.5.10-full

# 2. Directorio de trabajo
WORKDIR /app

# 3. Copia de configuración, datos, acciones y modelo pre-entrenado
COPY --chown=rasa:rasa \
  config.yml credentials.yml domain.yml endpoints.yml \
  data/ actions/ \
  /app/
COPY --chown=rasa:rasa \
  models/model-light.tar.gz \
  /app/models/model.tar.gz

# 4. Variables de entorno (Render inyecta el PORT correcto)
ENV RASA_ENVIRONMENT=production \
    SANIC_WORKERS=1 \
    PORT=10000

# 5. Expone dinámicamente el puerto
EXPOSE $PORT

# 6. Ejecuta como usuario no root
USER rasa

# 7. Anula cualquier ENTRYPOINT base
ENTRYPOINT []

# 8. Healthcheck para que Render considere tu servicio ‘healthy’
HEALTHCHECK --interval=15s --timeout=5s --start-period=5s \
  CMD curl -f http://localhost:$PORT/status || exit 1

# 9. Arranque en shell para expandir $PORT, con lazy-load
CMD rasa run --enable-api --cors "*" \
    -i 0.0.0.0 -p $PORT \
    --model /app/models/model.tar.gz \
    --lazy-load
