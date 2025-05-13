# 1) Imagen base oficial de Rasa
FROM rasa/rasa:3.5.10-full

# 2) Directorio de trabajo
WORKDIR /app

# 3) Copia de configuración, datos, acciones y endpoints
COPY --chown=rasa:rasa \
  config.yml credentials.yml domain.yml endpoints.yml \
  data/ actions/ \
  ./

# 4) Copia del modelo retrained compatible con Rasa 3.5.10
COPY --chown=rasa:rasa \
  models/crispy-grain-3.5.10.tar.gz \
  /app/models/crispy-grain.tar.gz

# 5) Variables de entorno
ENV RASA_ENVIRONMENT=production \
    SANIC_WORKERS=1 \
    PORT=10000

# 6) Exponer el puerto para Render
EXPOSE 10000

# 7) Ejecuta como usuario rasa
USER rasa

# 8) Elimina el ENTRYPOINT que trae la imagen base
ENTRYPOINT []

# 9) Healthcheck: espera hasta 90s antes de fallar, comprobando /status
HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3 \
  CMD curl -f http://localhost:10000/status || exit 1

# 10) CMD: arranca Rasa apuntando al modelo correcto y habilita API/CORS
CMD ["rasa","run",
     "--model","/app/models/crispy-grain.tar.gz",
     "--enable-api","--cors","*",
     "-i","0.0.0.0","-p","10000"]
