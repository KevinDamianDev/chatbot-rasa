# 1) Imagen base
FROM rasa/rasa:3.5.10-full

# 2) Directorio de trabajo
WORKDIR /app

# 3) Copia de archivos
COPY --chown=rasa:rasa \
  config.yml credentials.yml domain.yml endpoints.yml \
  data/ actions/ \
  ./

# 4) Copia tu nuevo modelo retrained
COPY --chown=rasa:rasa \
  models/crispy-grain-3.5.10.tar.gz \
  /app/models/crispy-grain.tar.gz

# 5) Env vars (PORT lo inyecta Render)
ENV RASA_ENVIRONMENT=production \
    SANIC_WORKERS=1 \
    PORT=10000

# 6) Expone el puerto estático 10000
EXPOSE 10000

# 7) Usuario no-root
USER rasa

# 8) Limpia ENTRYPOINT
ENTRYPOINT []

# 9) Healthcheck con start-period amplio para cargar el modelo
HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3 \
  CMD curl -f http://localhost:10000/status || exit 1

# 10) CMD que apunta explicitamente al modelo correcto
CMD ["rasa","run",
     "--model","/app/models/crispy-grain.tar.gz",
     "--enable-api","--cors","*",
     "-i","0.0.0.0","-p","10000"]
