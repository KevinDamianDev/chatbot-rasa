# 1) Base image oficial Rasa
FROM rasa/rasa:3.5.10-full

# 2) Directorio de trabajo en contenedor
WORKDIR /app

# 3) Copia de tu configuración, datos, acciones y modelo ya entrenado
COPY --chown=rasa:rasa \
    config.yml \
    credentials.yml \
    domain.yml \
    endpoints.yml \
    data/ \
    actions/ \
    models/crispy-grain-3.5.10.tar.gz \
    /app/

# 4) Indica a Docker que el contenedor usará el puerto 10000
EXPOSE 10000

# 5) Asegúrate de arrancar con el entrypoint correcto
ENTRYPOINT ["rasa"]

# 6) Y pásale SOLO los argumentos de 'run' (no dupliques "rasa")
CMD [
  "run",
  "--model", "/app/crispy-grain-3.5.10.tar.gz",
  "--enable-api",
  "--cors", "*",
  "-i", "0.0.0.0",
  "-p", "10000"
]
