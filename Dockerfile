# 1. Base image
FROM rasa/rasa:3.5.10-full

# 2. Directorio de trabajo
WORKDIR /app

# 3. Copia configuración, datos y acciones
COPY --chown=rasa:rasa \
  config.yml credentials.yml domain.yml endpoints.yml \
  ./  
COPY --chown=rasa:rasa data/ ./data
COPY --chown=rasa:rasa actions/ ./actions

# 4. Entrena el modelo aquí mismo
RUN rasa train --no-prompt

# 5. Variables de entorno para Rasa/Sanic
ENV RASA_ENVIRONMENT=production \
    SANIC_HOST=0.0.0.0 \
    SANIC_PORT=10000 \
    SANIC_WORKERS=1 \
    PORT=10000

# 6. Expone el puerto
EXPOSE 10000

# 7. Usuario rasa
USER rasa

# 8. Arranque sin especificar tar.gz (cargará el último modelo entrenado)
CMD ["rasa", "run", "--enable-api", "--cors", "*", "--port", "10000", "--debug"]