FROM python:3.14-slim AS builder

COPY --from=ghcr.io/astral-sh/uv:0.10.6 /uv /uvx /bin/

WORKDIR /app

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

COPY src/ ./src/
RUN uv sync --frozen --no-dev

FROM python:3.14-slim

WORKDIR /app

RUN addgroup --system --gid 10001 app && \
    adduser --system --uid 10001 --gid 10001 --no-create-home app

COPY --from=builder /app/.venv /app/.venv
COPY --from=builder /app/src /app/src

ENV PATH="/app/.venv/bin:$PATH"

USER app

EXPOSE 8080 8081

CMD ["python", "-m", "app.main"]
