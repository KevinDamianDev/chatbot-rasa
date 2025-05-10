# Dockerfile
FROM rasa/rasa:3.5.10-full

# Trabajamos como root
USER root
WORKDIR /app

# Copia configuración y tu bot
COPY config.yml credentials.yml domain.yml endpoints.yml ./
COPY data/           ./data
COPY actions/        ./actions
COPY models/         ./models

# Exponemos el puerto que Render usará (10000)
EXPOSE 10000

# Arrancamos Rasa directamente en el PORT que Render inyecta
ENTRYPOINT ["bash","-c","rasa run --enable-api --cors '*' --interface 0.0.0.0 --port ${PORT:-5005}"]
