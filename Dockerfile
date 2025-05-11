# ─────────────────────────────────────────────────────────────
# 1. Base image
# ─────────────────────────────────────────────────────────────
FROM rasa/rasa:3.5.10-full

WORKDIR /app

# ─────────────────────────────────────────────────────────────
# 2. Copia código, datos y acciones
# ─────────────────────────────────────────────────────────────
COPY --chown=rasa:rasa \
  config.yml credentials.yml domain.yml endpoints.yml ./
COPY --chown=rasa:rasa data    ./data
COPY --chown=rasa:rasa actions ./actions

# ─────────────────────────────────────────────────────────────
# 3. Copia el tar.gz original y crea un tar “fixed” en /app/models
# ─────────────────────────────────────────────────────────────
COPY --chown=rasa:rasa \
  models/20250501-095336-crispy-grain.tar.gz \
  /app/models/

RUN set -eux; \
    # crea un workspace temporal \
    mkdir -p /app/tmp_model; \
    # extrae el bundle original \
    tar -xzf /app/models/20250501-095336-crispy-grain.tar.gz -C /app/tmp_model; \
    # parchea el featurizer: .json → .pkl \
    mv /app/tmp_model/components/train_LexicalSyntacticFeaturizer2/feature_to_idx_dict.json \
       /app/tmp_model/components/train_LexicalSyntacticFeaturizer2/feature_to_idx_dict.pkl; \
    # renombra el metadata si Rasa lo necesita \
    if [ -f /app/tmp_model/metadata.json ]; then \
      mv /app/tmp_model/metadata.json /app/tmp_model/model_metadata.json; \
    fi; \
    # vuelve a empaquetar TODO en el tar.gz que Rasa cargará \
    tar -czf /app/models/20250501-095336-crispy-grain-fixed.tar.gz -C /app/tmp_model .; \
    # limpia \
    rm -rf /app/tmp_model; \
    # reemplaza el viejo tar.gz por el “fixed” \
    mv /app/models/20250501-095336-crispy-grain-fixed.tar.gz \
       /app/models/20250501-095336-crispy-grain.tar.gz

# ─────────────────────────────────────────────────────────────
# 4. Variables de entorno y puerto
# ─────────────────────────────────────────────────────────────
ENV RASA_ENVIRONMENT=production \
    SANIC_HOST=0.0.0.0 \
    SANIC_PORT=10000 \
    SANIC_WORKERS=1 \
    PORT=10000

EXPOSE 10000
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:10000/webhooks/rest/webhook || exit 1

# ─────────────────────────────────────────────────────────────
# 5. Ejecuta como rasa
# ─────────────────────────────────────────────────────────────
USER rasa
ENTRYPOINT []

# ─────────────────────────────────────────────────────────────
# 6. Arranque FORZANDO la carga de ese tar.gz parcheado
# ─────────────────────────────────────────────────────────────
CMD ["rasa","run", \
     "--model","/app/models/20250501-095336-crispy-grain.tar.gz", \
     "--enable-api","--cors","*","--port","10000","--debug"]
