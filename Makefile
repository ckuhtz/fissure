VENV = .venv
PYTHON = $(VENV)/bin/python
PIP = $(VENV)/bin/pip
PYTEST = $(VENV)/bin/pytest
COVERAGE = $(VENV)/bin/coverage
BLACK = $(VENV)/bin/black
PYLINT = $(VENV)/bin/pylint
MYPY = $(VENV)/bin/mypy

# Extract dev dependencies from pyproject.toml (static list)
# Optionally, generate this from pip if you prefer

.PHONY: all ensure-env ensure-deps install test lint format check coverage clean

# Default behavior: ensure venv and dependencies
all: ensure-env ensure-deps

# Step 1: Ensure virtual environment exists
ensure-env:
	@test -d $(VENV) || { \
		echo "🐍 Creating virtual environment..."; \
		python3 -m venv $(VENV); \
		$(PIP) install -U pip; \
	}

# Step 2: Ensure dev dependencies are installed
# We test by checking whether pytest is importable
ensure-deps: ensure-env
	@$(PYTHON) -c "import pytest, pylint, black, mypy" 2>/dev/null || { \
		echo '📦 Installing dev dependencies...'; \
		$(PIP) install -e .[dev]; \
	}

# Manual install (idempotent if ensure-deps works)
install: ensure-deps

# Testing
test: ensure-deps
	$(VENV)/bin/pytest

coverage: ensure-deps
	$(COVERAGE) run -m pytest
	$(COVERAGE) report
	$(COVERAGE) xml
	$(COVERAGE) html
	$(VENV)/bin/coverage-badge -o coverage.svg -f

# Linting / formatting / typing
lint: ensure-deps
	$(VENV)/bin/pylint src tests

format: ensure-deps
	$(VENV)/bin/black src tests

check: lint
	$(VENV)/bin/mypy src tests

# Cleanup
clean:
	rm -rf .pytest_cache .mypy_cache .coverage htmlcov build dist *.egg-info

# Docker
IMAGE_NAME := fissure-dev

.PHONY: docker-build docker-shell \
	docker-test docker-lint docker-format docker-check docker-coverage docker-install

# Build the Docker image with all dev tools and virtualenv installed
docker-build:
	docker build -t $(IMAGE_NAME) .

# Interactive shell (for debug or dev inside container)
docker-shell: docker-build
	docker run --rm -it \
		-v $(CURDIR):/app \
		-w /app \
		-e PATH="/opt/venv/bin:$$PATH" \
		$(IMAGE_NAME) bash

# Run test suite inside container
docker-test: docker-build
	docker run --rm \
		-v $(CURDIR):/app \
		-w /app \
		-e PATH="/opt/venv/bin:$$PATH" \
		$(IMAGE_NAME) make test

# Run linter inside container
docker-lint: docker-build
	docker run --rm \
		-v $(CURDIR):/app \
		-w /app \
		-e PATH="/opt/venv/bin:$$PATH" \
		$(IMAGE_NAME) make lint

# Run formatter inside container
docker-format: docker-build
	docker run --rm \
		-v $(CURDIR):/app \
		-w /app \
		-e PATH="/opt/venv/bin:$$PATH" \
		$(IMAGE_NAME) make format

# Run type checks inside container
docker-check: docker-build
	docker run --rm \
		-v $(CURDIR):/app \
		-w /app \
		-e PATH="/opt/venv/bin:$$PATH" \
		$(IMAGE_NAME) make check

# Run coverage analysis inside container
docker-coverage: docker-build
	docker run --rm \
		-v $(CURDIR):/app \
		-w /app \
		-e PATH="/opt/venv/bin:$$PATH" \
		$(IMAGE_NAME) make coverage

# Install dev dependencies into container's venv (if needed)
docker-install: docker-build
	docker run --rm \
		-v $(CURDIR):/app \
		-w /app \
		-e PATH="/opt/venv/bin:$$PATH" \
		$(IMAGE_NAME) make install