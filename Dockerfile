FROM rasa/rasa:3.5.10-full

WORKDIR /app

# 1. Copia primero las configuraciones, asignando dueño rasa:rasa
COPY --chown=rasa:rasa config.yml credentials.yml domain.yml endpoints.yml ./
COPY --chown=rasa:rasa data        ./data
COPY --chown=rasa:rasa actions     ./actions
COPY --chown=rasa:rasa models/20250501-095336-crispy-grain.tar.gz ./models/

# 2. Variables de entorno
ENV RASA_ENVIRONMENT=production \
    SANIC_HOST=0.0.0.0 \
    SANIC_PORT=10000 \
    SANIC_WORKERS=1

# 3. Exponer y ejecutar como el usuario rasa
EXPOSE 10000
USER rasa

ENTRYPOINT []
CMD ["rasa", "run", "--enable-api", "--cors", "*", "--port", "10000", "--debug"]
