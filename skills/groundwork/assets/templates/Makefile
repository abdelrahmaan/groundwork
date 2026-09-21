# <project_name> — one entry point for every command.
# MVP set only. Uncomment a target the day the project actually needs it.
.DEFAULT_GOAL := help
SHELL := /bin/bash

.PHONY: help install dev run fmt lint type test check ci docker-dev docker-prod logs clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

install: ## Install dependencies (uv, locked)
	uv sync --locked

dev: ## Run the API with reload
	uv run fastapi dev app/main.py

run: ## Run the API without reload
	uv run fastapi run app/main.py

fmt: ## Format code
	uv run ruff format .

lint: ## Lint and autofix
	uv run ruff check . --fix

type: ## Type check
	uv run pyright

test: ## Run tests
	uv run pytest -q

check: fmt lint type test ## Run before every commit (mutates files)

ci: ## Same checks, read-only — what CI runs
	uv run ruff format --check .
	uv run ruff check .
	uv run pyright
	uv run pytest -q

docker-dev: ## Start the dev stack
	docker compose up -d --build

docker-prod: ## Start the prod stack
	docker compose -f compose.yaml -f compose.prod.yaml up -d --build

logs: ## Tail api logs
	docker compose logs -f api

clean: ## Remove containers, volumes and caches
	docker compose down -v
	find . -type d -name __pycache__ -prune -exec rm -rf {} +

# ---------------------------------------------------------------------------
# Add these when the need appears (each depends on files that must exist first)
# ---------------------------------------------------------------------------
# migrate:      ## Apply DB migrations           — needs alembic/
# 	uv run alembic upgrade head
# revision:     ## New migration: make revision m="add users"
# 	uv run alembic revision --autogenerate -m "$(m)"
# downgrade:    ## Roll back one migration
# 	uv run alembic downgrade -1
# eval:         ## AI evals against the golden set — needs evals/
# 	uv run python -m evals.run
# load:         ## Load test staging              — needs load/locustfile.py
# 	uv run locust -f load/locustfile.py --host $${LOAD_TARGET:?set LOAD_TARGET}
# openapi:      ## Export the contract            — needs scripts/export_openapi.py
# 	uv run python -m scripts.export_openapi > openapi.json
