FROM rasa/rasa:3.5.10-full
WORKDIR /app

# Copia solo los archivos necesarios
COPY config.yml credentials.yml domain.yml endpoints.yml ./
COPY data ./data
COPY actions ./actions
COPY models ./models

# Puerto expuesto (debe coincidir con Render)
EXPOSE 10000

# Comando de inicio
CMD ["rasa", "run", "--enable-api", "--cors", "*", "--port", "10000"]