# syntax=docker/dockerfile:1.9
# Multi-stage: base -> dev (reload, dev deps) / prod (slim, non-root)
FROM python:3.12-slim AS base
# Pin the uv image like any other dependency; bump it deliberately.
COPY --from=ghcr.io/astral-sh/uv:0.9.7 /uv /uvx /bin/
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy PYTHONUNBUFFERED=1
WORKDIR /app

# ---- dependencies only (cached layer) ----
FROM base AS deps
COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv uv sync --locked --no-install-project

# ---- dev ----
FROM deps AS dev
COPY . .
RUN --mount=type=cache,target=/root/.cache/uv uv sync --locked
ENV PATH="/app/.venv/bin:$PATH"
CMD ["fastapi", "dev", "app/main.py", "--host", "0.0.0.0", "--port", "8000"]

# ---- prod ----
FROM deps AS prod
ENV UV_NO_DEV=1
COPY . .
RUN --mount=type=cache,target=/root/.cache/uv uv sync --locked --no-dev \
 && useradd -r -u 10001 appuser && chown -R appuser /app
USER appuser
ENV PATH="/app/.venv/bin:$PATH"
EXPOSE 8000
CMD ["fastapi", "run", "app/main.py", "--host", "0.0.0.0", "--port", "8000", "--proxy-headers"]
