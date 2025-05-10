FROM rasa/rasa:3.5.10-full

WORKDIR /app

# Copia tus archivos de Rasa
COPY config.yml credentials.yml domain.yml endpoints.yml ./
COPY data/           ./data
COPY actions/        ./actions
COPY models/         ./models

# Exponemos el puerto que usará Render
EXPOSE 10000

# Arrancamos Rasa directamente en primer plano
CMD ["rasa", "run", "--enable-api", "--cors", "*", "--interface", "0.0.0.0", "--port", "10000"]