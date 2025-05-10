FROM rasa/rasa:3.5.10-full
WORKDIR /app

COPY . .

# Puerto expuesto (debe coincidir con Render)
EXPOSE 10000

# Comando corregido:
CMD ["rasa", "run", "--enable-api", "--cors", "*", "--port", "10000"]