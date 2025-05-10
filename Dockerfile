FROM rasa/rasa:3.5.10-full

USER root
WORKDIR /app

# 1) Copia tus archivos de Rasa
COPY config.yml credentials.yml domain.yml endpoints.yml ./
COPY data/           ./data
COPY actions/        ./actions
COPY models/         ./models

# 2) Copia nginx.conf y start.sh
COPY nginx.conf      /app/nginx.conf
COPY start.sh        /app/start.sh
RUN chmod +x /app/start.sh

# 3) Instala nginx y limpia cache de apt
RUN apt-get update && \
    apt-get install -y nginx && \
    rm -rf /var/lib/apt/lists/*

# 4) Expone el puerto interno que Render asigna
EXPOSE 10000

# 5) Al arrancar, ejecuta start.sh
ENTRYPOINT ["bash", "/app/start.sh"]