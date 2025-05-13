# 1) Usa la imagen oficial de Rasa
FROM rasa/rasa:3.5.10-full

# 2) Ponemos /app como directorio de trabajo
WORKDIR /app

# 3) Copiamos todo lo necesario (config, datos, acciones y modelo ya entrenado)
COPY --chown=rasa:rasa \
    config.yml \
    credentials.yml \
    domain.yml \
    endpoints.yml \
    data/ \
    actions/ \
    models/crispy-grain-3.5.10.tar.gz \
    /app/

# 4) Exponemos el puerto que usaremos
EXPOSE 10000

# 5) Arrancamos Rasa TODO en una sola línea (evita errores de parseo)
CMD ["rasa","run","--model","/app/crispy-grain-3.5.10.tar.gz","--enable-api","--cors","*","-i","0.0.0.0","-p","10000"]
