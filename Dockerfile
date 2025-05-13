FROM rasa/rasa:3.5.10-full
WORKDIR /app

# Copias
COPY --chown=rasa:rasa \
  config.yml credentials.yml domain.yml endpoints.yml \
  data/ actions/ \
  models/20250501-095336-crispy-grain.tar.gz \
  ./

ENV RASA_ENVIRONMENT=production \
    SANIC_WORKERS=1 \
    PORT=10000

EXPOSE 10000
USER rasa
ENTRYPOINT []

# Healthcheck con start-period largo
HEALTHCHECK --interval=30s --timeout=5s --start-period=120s --retries=3 \
  CMD curl -f http://localhost:10000/status || exit 1

CMD ["rasa","run","--enable-api","--cors","*","-i","0.0.0.0","-p","10000","--model","./20250501-095336-crispy-grain.tar.gz"]