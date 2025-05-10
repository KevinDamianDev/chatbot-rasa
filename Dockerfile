FROM rasa/rasa:3.5.10-full

USER root
WORKDIR /app

# Copia tus archivos de Rasa
COPY config.yml credentials.yml domain.yml endpoints.yml ./ 
COPY data/           ./data
COPY actions/        ./actions
COPY models/         ./models

# Copia el script de arranque
COPY start.sh        /app/start.sh
RUN chmod +x /app/start.sh

# Exponemos el puerto que usará Render (internalPort: 10000)
EXPOSE 10000

# Arrancamos Rasa directamente
ENTRYPOINT ["bash","/app/start.sh"]