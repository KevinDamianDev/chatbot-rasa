FROM rasa/rasa:3.5.10-full

USER root
WORKDIR /app

COPY config.yml credentials.yml domain.yml endpoints.yml ./
COPY data/           ./data
COPY actions/        ./actions
COPY models/         ./models

# Copiamos el start.sh corregido
COPY start.sh        /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 10000

ENTRYPOINT ["bash", "/app/start.sh"]