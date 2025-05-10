FROM rasa/rasa:3.5.10-full

# Trabajamos como root para copiar y exponer el puerto
USER root
WORKDIR /app

# Copia todo el proyecto (config, models, actions, etc)
COPY . .

# Exponemos el puerto por defecto de Rasa (5005)
EXPOSE 5005

# Arrancamos Rasa directamente, usando la variable de entorno PORT que Render asigna
ENTRYPOINT ["bash", "-c", "rasa run --enable-api --cors '*' --interface 0.0.0.0 --port $PORT"]