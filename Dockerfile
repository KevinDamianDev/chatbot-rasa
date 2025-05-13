# 1. Imagen base oficial de Rasa
FROM rasa/rasa:3.5.10-full

# 2. Bust de cache (incrementa este valor si haces cambios al Dockerfile)
ARG CACHEBUST=1

# 3. Directorio de trabajo
WORKDIR /app

# 4. Copia de configuración, datos y acciones
COPY --chown=rasa:rasa \
  config.yml credentials.yml domain.yml endpoints.yml \
  data/ actions/ \
  ./

# 5. Copia el modelo ya entrenado (ajusta al nombre que tienes en tu repo)
COPY --chown=rasa:rasa \
  models/20250501-095336-crispy-grain.tar.gz \
  /app/models/model.tar.gz

# 6. Variables de entorno (Render inyecta el PORT)
ENV RASA_ENVIRONMENT=production \
    SANIC_WORKERS=1 \
    PORT=10000

# 7. Expone dinámicamente el puerto que Render usará
EXPOSE $PORT

# 8. Ejecuta como usuario no-root
USER rasa

# 9. Limpia el ENTRYPOINT de la imagen base
ENTRYPOINT []

# 10. Healthcheck para que Render compruebe /status
HEALTHCHECK --interval=15s --timeout=5s --start-period=5s \
  CMD curl -f http://localhost:$PORT/status || exit 1

# 11. CMD en forma shell para expandir $PORT y usar lazy-load
CMD rasa run --enable-api --cors "*" \
    -i 0.0.0.0 -p $PORT \
    --model /app/models/model.tar.gz \
    --lazy-load
