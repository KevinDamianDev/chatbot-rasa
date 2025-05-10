FROM rasa/rasa:3.5.10-full

USER root

WORKDIR /app

COPY config.yml credentials.yml domain.yml endpoints.yml ./
COPY data ./data
COPY actions ./actions
COPY models ./models

# Asegura los permisos correctos
RUN chown -R rasa:rasa /app && \
    chmod -R 755 /app

USER rasa

EXPOSE 10000

# Comando de inicio CORREGIDO (formato array JSON estricto)
CMD ["python", "-m", "rasa", "run", "--enable-api", "--cors", "*", "--port", "10000"]