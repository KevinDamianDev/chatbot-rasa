# 1. Base image
FROM rasa/rasa:3.5.10-full

# 2. Cache bust (cámbialo cuando vuelvas a push para invalidar caché)
ARG CACHEBUST=1

# 3. Set workdir
WORKDIR /app

# 4. Copy your files
COPY --chown=rasa:rasa config.yml credentials.yml domain.yml endpoints.yml ./
COPY --chown=rasa:rasa data/ ./data
COPY --chown=rasa:rasa actions/ ./actions

# 5. Train model at build time
RUN rasa train

# 6. Env vars (Render inyecta PORT automáticamente)
ENV RASA_ENVIRONMENT=production \
    SANIC_WORKERS=1 \
    PORT=10000

# 7. Expose the dynamic port
EXPOSE $PORT

# 8. User
USER rasa

# 9. Clear base image ENTRYPOINT
ENTRYPOINT []

# 10. Healthcheck so Render sees readiness
HEALTHCHECK --interval=15s --timeout=5s --start-period=5s \
  CMD curl -f http://localhost:$PORT/status || exit 1

# 11. CMD as JSON calling `sh -c` to expand $PORT
CMD ["sh", "-c", "echo \"==> Listening on 0.0.0.0:$PORT\" && rasa run --enable-api --cors \"*\" -i 0.0.0.0 -p $PORT --debug"]