# 1. Base image
FROM rasa/rasa:3.5.10-full

# 2. Workdir
WORKDIR /app

# 3. Copia de ficheros y modelo entrenado
COPY --chown=rasa:rasa \
  config.yml credentials.yml domain.yml endpoints.yml \
  data/ actions/ \
  ./
COPY --chown=rasa:rasa \
  models/20250501-095336-crispy-grain.tar.gz \
  /app/models/model.tar.gz

# 4. Env vars (PORT lo inyecta Render)
ENV RASA_ENVIRONMENT=production \
    SANIC_WORKERS=1 \
    PORT=10000

# 5. Exponer puerto
EXPOSE $PORT

# 6. Usuario no-root
USER rasa

# 7. Quitar ENTRYPOINT base
ENTRYPOINT []

# 8. Healthcheck
HEALTHCHECK --interval=15s --timeout=5s --start-period=5s \
  CMD curl -f http://localhost:$PORT/status || exit 1

# 9. Script de arranque
CMD bash -c "\
  # 1) Arranco Rasa sin modelo (abrirá puerto y responderá /status) \
  rasa run --enable-api --cors '*' -i 0.0.0.0 -p \$PORT & \
  RASA_PID=\$!; \
  # 2) Espero un segundo para que Sanic esté listo \
  sleep 1; \
  # 3) Subo el modelo vía REST \
  curl -X PUT http://localhost:\$PORT/model -F model=@/app/models/model.tar.gz; \
  # 4) Espero al proceso principal \
  wait \$RASA_PID \
"