FROM rasa/rasa:3.5.10-full

WORKDIR /app

# Copia tus archivos
COPY config.yml credentials.yml domain.yml endpoints.yml ./
COPY data/           ./data
COPY actions/        ./actions
COPY models/         ./models

# Exponemos el puerto que usará Render
EXPOSE 10000

# Anula el entrypoint original de la imagen
ENTRYPOINT []

# Arranca Rasa en primer plano, en el puerto 10000
CMD ["rasa", "run", "--enable-api", "--cors", "*", "--interface", "0.0.0.0", "--port", "10000"]