# Usa la imagen oficial de Rasa 3.5.10
FROM rasa/rasa:3.5.10-full

# Trabajamos como root para copiar archivos
USER root
WORKDIR /app

# 1) Copia la configuración y tu data
COPY --chown=rasa:rasa \
  config.yml credentials.yml domain.yml endpoints.yml \
  ./

# 2) Copia tu carpeta de datos NLU & stories
COPY --chown=rasa:rasa data/ data/

# 3) Copia tu modelo pre-entrenado (renómbralo localmente a model.tar.gz)
COPY --chown=rasa:rasa \
  models/crispy-grain-3.5.10.tar.gz \
  models/model.tar.gz

# 4) Copia tus acciones personalizadas
COPY --chown=rasa:rasa actions/ actions/

# 5) Cambia al usuario rasa (la imagen oficial lo espera así)
USER rasa

# 6) Expone el puerto en el que Rasa verá tráfico
EXPOSE 10000

# 7) Arranca Rasa apuntando explícito al modelo dentro de /app/models
CMD ["rasa","run","--model","/app/models/model.tar.gz","--enable-api","--cors","*","-i","0.0.0.0","-p","10000"]
