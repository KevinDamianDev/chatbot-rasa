FROM rasa/rasa:3.5.10-full

USER root
WORKDIR /app

COPY config.yml credentials.yml domain.yml endpoints.yml ./
COPY data/ ./data
COPY actions/ ./actions
COPY models/ ./models

# Copia el nuevo start.sh
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 10000

# Únicamente arranca Rasa
ENTRYPOINT ["bash", "/app/start.sh"]
