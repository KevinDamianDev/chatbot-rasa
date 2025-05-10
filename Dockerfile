FROM rasa/rasa:3.5.10-full

USER root
WORKDIR /app

COPY config.yml credentials.yml domain.yml endpoints.yml ./
COPY data/ data
COPY actions/ actions
COPY models/ models

# Copia y da permisos
COPY nginx.conf start.sh ./
RUN chmod +x start.sh

# Instala Nginx
RUN apt-get update \
 && apt-get install -y nginx \
 && rm -rf /var/lib/apt/lists/*

EXPOSE 10000

# Usa nuestro script de arranque
ENTRYPOINT ["bash", "/app/start.sh"]