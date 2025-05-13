# 1. Imagen base oficial de Rasa
FROM rasa/rasa:3.5.10-full

# 2. Directorio de trabajo
WORKDIR /app

# 3. Copia de configuración, datos y acciones
COPY --chown=rasa:rasa \
  config.yml credentials.yml domain.yml endpoints.yml \
  ./
COPY --chown=rasa:rasa data/ ./data
COPY --chown=rasa:rasa actions/ ./actions

# 4. Entrena el modelo durante el build
RUN rasa train

# 5. Variables de entorno para Rasa y Sanic
ENV RASA_ENVIRONMENT=production \
    SANIC_HOST=0.0.0.0 \
    SANIC_PORT=10000 \
    SANIC_WORKERS=1 \
    PORT=10000

# 6. Expone el puerto que usa Render (10000)
EXPOSE 10000

# 7. Ejecuta como el usuario rasa
USER rasa

# 8. Anula el ENTRYPOINT de la imagen base 
ENTRYPOINT []

# 9. Arranca el servidor Rasa con la API habilitada
CMD ["rasa", "run", "--enable-api", "--cors", "*", "--port", "10000", "--debug"]