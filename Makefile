VENV := .venv
PYTHON := $(VENV)/bin/python
PIP := $(VENV)/bin/pip
REQFILE := requirements-dev.txt

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
	$(VENV)/bin/coverage run -m pytest
	$(VENV)/bin/coverage report
	$(VENV)/bin/coverage html

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
	