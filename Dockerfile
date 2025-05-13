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

# 5. Variables de entorno para Rasa/Sanic
ENV RASA_ENVIRONMENT=production \
    SANIC_WORKERS=1 \
    PORT=10000

# 6. Expone el puerto que usa Render
EXPOSE 10000

# 7. Ejecuta como el usuario rasa
USER rasa

# 8. Anula el ENTRYPOINT de la imagen base
ENTRYPOINT []

# 9. Arranca Rasa escuchando en todas las interfaces y en el puerto 10000
CMD ["rasa", "run", "-i", "0.0.0.0", "-p", "10000", "--enable-api", "--cors", "*", "--debug"]