# syntax=docker/dockerfile:1

FROM python:3.12.11-slim-bookworm AS build
WORKDIR /build
COPY app.py .

FROM python:3.12.11-slim-bookworm AS runtime
WORKDIR /app
COPY --from=build /build/app.py ./app.py

RUN groupadd --gid 10001 appuser \
    && useradd --uid 10001 --gid appuser --home-dir /app --shell /usr/sbin/nologin --no-create-home appuser \
    && chown -R appuser:appuser /app

ENV APP_NAME=demo-service \
    VERSION=1.0.0 \
    PORT=8080

USER 10001:10001
EXPOSE 8080
CMD ["python", "app.py"]
