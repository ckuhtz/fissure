VENV := .venv
PYTHON := $(VENV)/bin/python
PIP := $(VENV)/bin/pip
PYTEST := $(VENV)/bin/pytest
COVERAGE := $(VENV)/bin/coverage
BLACK := $(VENV)/bin/black
PYLINT := $(VENV)/bin/pylint
MYPY := $(VENV)/bin/mypy
IMAGE_NAME := fissure-dev

.DEFAULT_GOAL := test

.PHONY: all venv install ensure-env ensure-deps test lint format check coverage clean \
        docker-build docker-test docker-lint docker-check docker-coverage docker-shell \
        preflight pr

# -------------------------------
# 🛠️  Virtualenv Setup
# -------------------------------

all: test

venv:
	python3 -m venv $(VENV)
	$(PIP) install -U pip

ensure-env:
	@test -d $(VENV) || { \
		echo "🐍 Creating virtual environment..."; \
		python3 -m venv $(VENV); \
		$(PIP) install -U pip; \
	}

ensure-deps: ensure-env
	@$(PYTHON) -c "import pytest, pylint, black, mypy" 2>/dev/null || { \
		echo '📦 Installing dev dependencies...'; \
		$(PIP) install -e .[dev]; \
	}

install: ensure-deps

# -------------------------------
# 🧪 Core Tasks
# -------------------------------

test: ensure-deps
	$(PYTEST)

lint: ensure-deps
	$(PYLINT) src tests

format: ensure-deps
	$(BLACK) src tests

check: lint
	$(MYPY) src tests

coverage: ensure-deps
	$(COVERAGE) run -m pytest
	$(COVERAGE) report
	$(COVERAGE) xml
	$(COVERAGE) html
	$(VENV)/bin/coverage-badge -o coverage.svg -f

clean:
	rm -rf .pytest_cache .mypy_cache .coverage htmlcov build dist *.egg-info coverage.svg results.xml

# -------------------------------
# 🐳 Dockerized Versions
# -------------------------------

docker-build:
	docker build -t $(IMAGE_NAME) .

docker-shell: docker-build
	docker run --rm -it -v $(CURDIR):/app -w /app -e PATH="/opt/venv/bin:$$PATH" $(IMAGE_NAME) bash

docker-test: docker-build
	docker run --rm -v $(CURDIR):/app -w /app -e PATH="/opt/venv/bin:$$PATH" $(IMAGE_NAME) make test

docker-lint: docker-build
	docker run --rm -v $(CURDIR):/app -w /app -e PATH="/opt/venv/bin:$$PATH" $(IMAGE_NAME) make lint

docker-check: docker-build
	docker run --rm -v $(CURDIR):/app -w /app -e PATH="/opt/venv/bin:$$PATH" $(IMAGE_NAME) make check

docker-coverage: docker-build
	docker run --rm -v $(CURDIR):/app -w /app -e PATH="/opt/venv/bin:$$PATH" $(IMAGE_NAME) make coverage

# -------------------------------
# 🚦 Preflight Checks
# -------------------------------

preflight:
	@echo "🚦 Running preflight checks..."

	@command -v make >/dev/null 2>&1 || { \
		echo "❌ 'make' is required but not installed."; exit 1; \
	}

	@command -v docker >/dev/null 2>&1 || { \
		echo "❌ 'docker' is required but not installed."; exit 1; \
	}

	@command -v gh >/dev/null 2>&1 || { \
		echo "🔍 'gh' (GitHub CLI) not found. Attempting to install..."; \
		if command -v brew >/dev/null 2>&1; then \
			brew install gh; \
		elif command -v apt >/dev/null 2>&1; then \
			sudo apt update && sudo apt install -y gh; \
		elif command -v dnf >/dev/null 2>&1; then \
			sudo dnf install -y gh; \
		else \
			echo "❌ Cannot install 'gh' automatically on this platform."; \
			exit 1; \
		fi; \
	}

# -------------------------------
# 🔀 GitHub PR Automation
# -------------------------------

pr: preflight
	@branch=$$(git rev-parse --abbrev-ref HEAD); \
	if [ "$$branch" = "main" ]; then \
		echo "❌ Refusing to create a PR from 'main' branch."; \
		exit 1; \
	fi; \
	echo "🚀 Pushing '$$branch' and creating PR..."; \
	git push -u origin "$$branch"; \
	gh pr create --fill --web