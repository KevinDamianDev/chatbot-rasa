# Imagen base con Python 3.10
FROM python:3.10-slim

# Evita los prompts interactivos
ENV DEBIAN_FRONTEND=noninteractive

# Instala dependencias necesarias
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    curl \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Establece directorio de trabajo
WORKDIR /app

# Copia los archivos del proyecto al contenedor
COPY . /app

# Instala pip actualizado
RUN pip install --upgrade pip

# Instala las dependencias del proyecto
RUN pip install -r requirements.txt

# Expone el puerto que Render asigna dinámicamente
EXPOSE 5005

CMD ["sh", "-c", "rasa run --enable-api --cors '*' --debug --port $PORT"]