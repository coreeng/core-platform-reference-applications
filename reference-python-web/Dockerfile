FROM python:3.14.7-slim AS builder

COPY --from=docker.io/astral/uv:0.12.19 /uv /uvx /bin/

WORKDIR /app

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

COPY src/ ./src/
RUN uv sync --frozen --no-dev

FROM python:3.14.7-slim

WORKDIR /app

RUN addgroup --system --gid 10001 app && \
    adduser --system --uid 10001 --gid 10001 --no-create-home app && \
    rm -rf /usr/local/bin/pip* /usr/local/lib/python3.14/site-packages/pip*

COPY --from=builder /app/.venv /app/.venv
COPY --from=builder /app/src /app/src

ENV PATH="/app/.venv/bin:$PATH"

USER app

EXPOSE 8080 8081

CMD ["python", "-m", "app.main"]
