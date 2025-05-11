FROM rasa/rasa:3.5.10-full
WORKDIR /app

# 1. Config y código
COPY --chown=rasa:rasa \
  config.yml credentials.yml domain.yml endpoints.yml ./
COPY --chown=rasa:rasa data    ./data
COPY --chown=rasa:rasa actions ./actions

# 2. Copia el tar.gz original y repácalo corrigiendo sólo el feature_to_idx_dict
COPY --chown=rasa:rasa \
  models/20250501-095336-crispy-grain.tar.gz \
  /app/models/

RUN set -eux; \
    mkdir -p /app/tmp_model; \
    tar -xzf /app/models/20250501-095336-crispy-grain.tar.gz -C /app/tmp_model; \
    mv /app/tmp_model/components/train_LexicalSyntacticFeaturizer2/feature_to_idx_dict.json \
       /app/tmp_model/components/train_LexicalSyntacticFeaturizer2/feature_to_idx_dict.pkl; \
    tar -czf /app/models/20250501-095336-crispy-grain-fixed.tar.gz \
         -C /app/tmp_model .; \
    rm -rf /app/tmp_model; \
    mv /app/models/20250501-095336-crispy-grain-fixed.tar.gz \
       /app/models/20250501-095336-crispy-grain.tar.gz

# 3. Entorno y puerto para Render
ENV RASA_ENVIRONMENT=production \
    SANIC_HOST=0.0.0.0 \
    SANIC_PORT=10000 \
    SANIC_WORKERS=1 \
    PORT=10000

EXPOSE 10000
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:10000/webhooks/rest/webhook || exit 1

USER rasa
ENTRYPOINT []

# 4. Forzar carga del tarball parcheado
CMD ["rasa","run", \
     "--model","/app/models/20250501-095336-crispy-grain.tar.gz", \
     "--enable-api","--cors","*","--port","10000","--debug"]