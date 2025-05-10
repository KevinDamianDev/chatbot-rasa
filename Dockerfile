FROM rasa/rasa:3.5.10-full

WORKDIR /app

# 1. Copia selectiva de archivos (evita conflictos)
COPY --chown=rasa:rasa config.yml .
COPY --chown=rasa:rasa credentials.yml .
COPY --chown=rasa:rasa domain.yml .
COPY --chown=rasa:rasa endpoints.yml .
COPY --chown=rasa:rasa data/nlu.yml data/nlu.yml
COPY --chown=rasa:rasa data/stories.yml data/stories.yml
COPY --chown=rasa:rasa data/rules.yml data/rules.yml
COPY --chown=rasa:rasa actions/actions.py actions/actions.py
COPY --chown=rasa:rasa actions/__init__.py actions/__init__.py
COPY --chown=rasa:rasa models/*.tar.gz models/

# 2. Configuración de salud mejorada
HEALTHCHECK --interval=30s --timeout=10s \
    CMD curl -f http://localhost:10000 || exit 1

# 3. Variables de entorno críticas
ENV RASA_ENVIRONMENT=production
ENV SANIC_WORKERS=1

# 4. Comando indestructible
USER rasa
EXPOSE 10000
ENTRYPOINT []
CMD ["/bin/bash", "-c", "rasa run --enable-api --cors '*' --port 10000 --debug"]