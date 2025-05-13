# 1. Imagen base oficial de Rasa
FROM rasa/rasa:3.5.10-full

# 2. Forzar bust de cache
ARG CACHEBUST=1

# 3. Directorio de trabajo
WORKDIR /app

# 4. Copia de configuración, datos y acciones
COPY --chown=rasa:rasa config.yml credentials.yml domain.yml endpoints.yml ./
COPY --chown=rasa:rasa data/ ./data
COPY --chown=rasa:rasa actions/ ./actions

# 5. Entrena el modelo durante el build (cache busted)
RUN rasa train

# 6. Variables de entorno
ENV RASA_ENVIRONMENT=production \
    SANIC_WORKERS=1 \
    PORT=10000

# 7. Expone el puerto que usa Render
EXPOSE 10000

# 8. Usuario rasa
USER rasa

# 9. Limpia entrypoint base
ENTRYPOINT []

# 10. Arranque con flags correctos (-i, -p)
CMD ["rasa", "run", "-i", "0.0.0.0", "-p", "10000", "--enable-api", "--cors", "*"]