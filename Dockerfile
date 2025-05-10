FROM rasa/rasa:3.5.10-full

USER root
WORKDIR /app

# Copia tus archivos de Rasa
COPY config.yml credentials.yml domain.yml endpoints.yml ./ 
COPY data/           ./data
COPY actions/        ./actions
COPY models/         ./models

# Copia la configuración de nginx y tu script de arranque
COPY nginx.conf      /app/nginx.conf
COPY start.sh        /app/start.sh
RUN chmod +x /app/start.sh

# Instala nginx
RUN apt-get update && \
    apt-get install -y nginx && \
    rm -rf /var/lib/apt/lists/*

# Exponemos el puerto que usará Render (internalPort: 10000)
EXPOSE 10000

# Arrancamos nginx + Rasa
ENTRYPOINT ["bash","/app/start.sh"]