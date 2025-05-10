FROM rasa/rasa:3.5.10-full

WORKDIR /app

# Copiamos configs y código
COPY config.yml credentials.yml domain.yml endpoints.yml ./
COPY data/ data/
COPY actions/ actions/
COPY models/ models/

# Exponemos el puerto que Render use internamente
EXPOSE 10000

# Arrancamos Rasa con el flag correcto --host, leyendo PORT
CMD ["bash", "-c", "rasa run --enable-api --cors '*' --host 0.0.0.0 --port ${PORT}"]
