FROM rasa/rasa:3.5.10-full

WORKDIR /app

COPY --chown=rasa:rasa \
  config.yml credentials.yml domain.yml endpoints.yml \
  data/ actions/ \
  ./

COPY --chown=rasa:rasa \
  models/crispy-grain-3.5.10.tar.gz \
  /app/models/crispy-grain.tar.gz

ENV RASA_ENVIRONMENT=production \
    SANIC_WORKERS=1 \
    PORT=10000

EXPOSE 10000

USER rasa
ENTRYPOINT []

HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3 \
  CMD curl -f http://localhost:10000/status || exit 1

# <-- Atención: todo el array JSON de CMD en una sola línea! -->
CMD ["rasa","run","--model","/app/models/crispy-grain.tar.gz","--enable-api","--cors","*","-i","0.0.0.0","-p","10000"]
