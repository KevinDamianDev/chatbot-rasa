FROM rasa/rasa:3.5.10-full

WORKDIR /app

# Copia solo lo esencial (archivo por archivo)
COPY config.yml .
COPY credentials.yml .
COPY domain.yml .
COPY endpoints.yml .
COPY data/nlu.yml data/nlu.yml
COPY data/stories.yml data/stories.yml
COPY data/rules.yml data/rules.yml
COPY actions/actions.py actions/actions.py
COPY actions/__init__.py actions/__init__.py
COPY models/*.tar.gz models/

# Comando a prueba de errores
ENTRYPOINT []
CMD ["/bin/bash", "-c", "rasa run --enable-api --cors '*' --port 10000"]