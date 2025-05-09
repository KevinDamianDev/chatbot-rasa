FROM rasa/rasa:3.5.10-full

WORKDIR /app

# Copia solo lo necesario
COPY config.yml       .
COPY credentials.yml  .
COPY domain.yml       .
COPY endpoints.yml    .
COPY data/            ./data
COPY actions/         ./actions
COPY models/          ./models

# Copia y marca ejecutable el script
COPY start.sh         .
RUN chmod +x start.sh

# Exponemos el puerto que Render asigna (10000 por defecto en web services free)
EXPOSE 10000

# Entrypoint = nuestro wrapper
ENTRYPOINT ["./start.sh"]