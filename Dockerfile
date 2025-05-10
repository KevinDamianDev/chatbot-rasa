FROM rasa/rasa:3.5.10-full
WORKDIR /app

# Copia solo los archivos necesarios (evita copiar venv/, etc.)
COPY config.yml credentials.yml domain.yml endpoints.yml ./
COPY data ./data
COPY actions ./actions
COPY models ./models

# Instala dependencias de acciones personalizadas si es necesario
RUN pip install --no-cache-dir -r actions/requirements.txt  # Si tienes este archivo

# Puerto expuesto (debe coincidir con Render)
EXPOSE 10000

# Comando CORREGIDO (formato JSON array para CMD)
CMD ["rasa", "run", "--enable-api", "--cors", "*", "--port", "10000"]