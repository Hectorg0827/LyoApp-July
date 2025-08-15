.PHONY: help install dev test lint format type-check security clean build docker-build docker-run migrate seed deploy health

# Default target
help:
	@echo "LyoApp Backend - Available commands:"
	@echo "  install       - Install dependencies with Poetry"
	@echo "  dev           - Run development server"
	@echo "  test          - Run tests with coverage"
	@echo "  lint          - Run linting (ruff)"
	@echo "  format        - Format code (black + ruff)"
	@echo "  type-check    - Run type checking (mypy)"
	@echo "  security      - Run security checks"
	@echo "  clean         - Clean cache and temp files"
	@echo "  build         - Build Docker image"
	@echo "  docker-build  - Build Docker image for production"
	@echo "  docker-run    - Run with docker-compose"
	@echo "  migrate       - Run database migrations"
	@echo "  seed          - Seed database with test data"
	@echo "  deploy        - Deploy to Google Cloud Run"
	@echo "  health        - Check service health"

# Development setup
install:
	poetry install
	poetry run pre-commit install

dev:
	poetry run uvicorn main:app --host 0.0.0.0 --port 8000 --reload

# Testing and quality
test:
	poetry run pytest -v --cov=src --cov-report=term-missing --cov-report=html

lint:
	poetry run ruff check src tests

format:
	poetry run black src tests
	poetry run ruff check src tests --fix

type-check:
	poetry run mypy src

security:
	poetry run bandit -r src

# Database operations
db-upgrade:
	alembic upgrade head

db-downgrade:
	alembic downgrade -1

db-reset:
	alembic downgrade base
	alembic upgrade head

db-seed:
	python seed_data.py

db-fresh: db-reset db-seed

# Database migrations
db-revision:
	alembic revision --autogenerate -m "$(MSG)"

db-current:
	alembic current

db-history:
	alembic history

db-show:
	alembic show head

# Docker operations
docker-build:
	docker build -t lyoapp-backend .

docker-run:
	docker-compose up --build

# Cleanup
clean:
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	find . -type f -name ".coverage" -delete
	find . -type d -name "htmlcov" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	find . -type d -name ".ruff_cache" -exec rm -rf {} +

# Production deployment
build: clean
	poetry export -f requirements.txt --output requirements.txt --without-hashes
	docker build -t lyoapp-backend:latest .

deploy: build
	@echo "Deploying to Google Cloud Run..."
	docker tag lyoapp-backend:latest gcr.io/$(GOOGLE_CLOUD_PROJECT)/lyoapp-backend:latest
	docker push gcr.io/$(GOOGLE_CLOUD_PROJECT)/lyoapp-backend:latest
	gcloud run deploy lyoapp-backend \
		--image gcr.io/$(GOOGLE_CLOUD_PROJECT)/lyoapp-backend:latest \
		--platform managed \
		--region us-central1 \
		--allow-unauthenticated \
		--memory 1Gi \
		--cpu 1 \
		--min-instances 0 \
		--max-instances 10 \
		--port 8000

# Health checks
health:
	@curl -s http://localhost:8000/health | python -m json.tool || echo "Service not running"

health-ready:
	@curl -s http://localhost:8000/health/ready | python -m json.tool || echo "Service not ready"

# Development utilities
shell:
	poetry shell

requirements:
	poetry export -f requirements.txt --output requirements.txt --without-hashes

update:
	poetry update

# Self-check (mandatory after every change)
self-check: lint type-check test
	@echo "✅ All checks passed!"
	@echo "Running health check..."
	@poetry run uvicorn main:app --host 0.0.0.0 --port 8000 &
	@sleep 5
	@curl -f http://localhost:8000/health > /dev/null && echo "✅ Health check passed!" || echo "❌ Health check failed!"
	@pkill -f "uvicorn main:app" || true
