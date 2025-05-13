# 1. Imagen base oficial de Rasa
FROM rasa/rasa:3.5.10-full

# 2. Directorio de trabajo
WORKDIR /app

# 3. Copia de configuración, datos y acciones
COPY --chown=rasa:rasa config.yml credentials.yml domain.yml endpoints.yml ./
COPY --chown=rasa:rasa data/ ./data
COPY --chown=rasa:rasa actions/ ./actions

# 4. Entrena el modelo durante el build
RUN rasa train

# 5. Variables de entorno para Rasa/Sanic (PORT lo setea Render)
ENV RASA_ENVIRONMENT=production \
    SANIC_WORKERS=1 \
    PORT=10000

# 6. Expone el puerto que usa Render (igual al interno)
EXPOSE 10000

# 7. Ejecuta como el usuario rasa
USER rasa

# 8. Limpia el entrypoint de la imagen base
ENTRYPOINT []

# 9. Shell-CMD para que $PORT se expanda correctamente en runtime
CMD rasa run -i 0.0.0.0 -p $PORT --enable-api --cors "*" --debug