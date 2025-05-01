VENV = .venv
PYTHON = $(VENV)/bin/python
PIP = $(VENV)/bin/pip
PYTEST = $(VENV)/bin/pytest
COVERAGE = $(VENV)/bin/coverage
BLACK = $(VENV)/bin/black
PYLINT = $(VENV)/bin/pylint
MYPY = $(VENV)/bin/mypy

.PHONY: all venv install test lint format check clean

all: test

venv:
	python3 -m venv $(VENV)
	$(PIP) install -U pip

install: venv
	$(PIP) install -e .[dev]

test:
	$(PYTEST)

coverage:
	$(COVERAGE) run -m pytest
	$(COVERAGE) report
	$(COVERAGE) html

lint:
	$(PYLINT) src tests

format:
	$(BLACK) src tests

check: lint
	$(MYPY) src tests

clean:
	rm -rf .pytest_cache .mypy_cache .coverage htmlcov build dist *.egg-info
	