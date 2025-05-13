# 1. Base
FROM rasa/rasa:3.5.10-full

# 2. Forzar bust de cache (cámbialo cuando vuelvas a push)
ARG CACHEBUST=1

# 3. Trabajo
WORKDIR /app

# 4. Copia fuentes
COPY --chown=rasa:rasa config.yml credentials.yml domain.yml endpoints.yml ./
COPY --chown=rasa:rasa data/ ./data
COPY --chown=rasa:rasa actions/ ./actions

# 5. Entrena modelo
RUN rasa train

# 6. Variables (PORT inyectado por Render)
ENV RASA_ENVIRONMENT=production \
    SANIC_WORKERS=1 \
    PORT=10000

# 7. Expone el puerto que acuerdas con internalPort
EXPOSE 10000

# 8. Privilegios
USER rasa

# 9. Quita entrypoint base
ENTRYPOINT []

# 10. **Shell-CMD**: aquí $PORT se expande en runtime
#     NOTA: no uses JSON array, sino shell form.
CMD rasa run -i 0.0.0.0 -p $PORT --enable-api --cors "*" --debug