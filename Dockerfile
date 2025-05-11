# Dockerfile completo con parche para el featurizer faltante

FROM rasa/rasa:3.5.10-full

WORKDIR /app

# 1. Copia de configuraciones con propietario rasa:rasa
COPY --chown=rasa:rasa \
  config.yml credentials.yml domain.yml endpoints.yml \
  ./

# 2. Copia de datos y acciones
COPY --chown=rasa:rasa data        ./data
COPY --chown=rasa:rasa actions     ./actions

# 3. Copia del modelo original
COPY --chown=rasa:rasa \
  models/20250501-095336-crispy-grain.tar.gz \
  ./models/

# 4. Parche en build-time: descomprime, renombra .json → .pkl y vuelve a empaquetar
RUN mkdir /app/tmp_model \
 && tar -xzf /app/models/20250501-095336-crispy-grain.tar.gz -C /app/tmp_model \
 && mv /app/tmp_model/components/train_LexicalSyntacticFeaturizer2/feature_to_idx_dict.json \
       /app/tmp_model/components/train_LexicalSyntacticFeaturizer2/feature_to_idx_dict.pkl \
 && tar -czf /app/models/20250501-095336-crispy-grain.tar.gz -C /app/tmp_model . \
 && rm -rf /app/tmp_model

# 5. Variables de entorno de Sanic/Rasa
ENV RASA_ENVIRONMENT=production \
    SANIC_HOST=0.0.0.0 \
    SANIC_PORT=10000 \
    SANIC_WORKERS=1

# 6. Exponer puerto y healthcheck
EXPOSE 10000
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:10000/webhooks/rest/webhook || exit 1

# 7. Cambiar a usuario rasa y comando de arranque
USER rasa
ENTRYPOINT []
CMD ["rasa", "run", "--enable-api", "--cors", "*", "--port", "10000", "--debug"]