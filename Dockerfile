FROM rasa/rasa:3.5.10-full

# 1) súbete a root para cambiar permisos
USER root

WORKDIR /app

COPY config.yml       .
COPY credentials.yml  .
COPY domain.yml       .
COPY endpoints.yml    .
COPY data/            ./data
COPY actions/         ./actions
COPY models/          ./models

COPY start.sh         .
RUN chmod +x start.sh

EXPOSE 10000

# 2) (opcional) puedes seguir como root o volver al usuario por defecto
# USER 1001

CMD ["./start.sh"]