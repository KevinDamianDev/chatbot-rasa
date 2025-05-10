# Dockerfile definitivo

FROM rasa/rasa:3.5.10-full

WORKDIR /app

# Copiamos configs, data, acciones y modelo
COPY config.yml credentials.yml domain.yml endpoints.yml ./
COPY data/           ./data
COPY actions/        ./actions
COPY models/         ./models

# Exponemos el puerto que Render inyecta internamente
EXPOSE 10000

# 1) Elimina el entrypoint de la imagen base
ENTRYPOINT []

# 2) Arrancamos rasa directamente, hardcodeando el puerto 10000
CMD ["rasa", "run", "--enable-api", "--cors", "*", "--host", "0.0.0.0", "--port", "10000"]