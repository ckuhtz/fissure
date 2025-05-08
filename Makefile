VENV := .venv
PYTHON := $(VENV)/bin/python
PIP := $(VENV)/bin/pip
PYTEST := $(VENV)/bin/pytest
COVERAGE := $(VENV)/bin/coverage
BLACK := $(VENV)/bin/black
PYLINT := $(VENV)/bin/pylint
MYPY := $(VENV)/bin/mypy
IMAGE_NAME := fissure-dev
THRIFT := $(shell command -v thrift)
THRIFT_IDL_DIR = spec/
THRIFT_GEN_DIR = src/gen-py

.DEFAULT_GOAL := default

.PHONY: default help all venv install ensure-env ensure-thrift ensure-deps test lint format check coverage \
		clean dist-clean docker-build docker-test docker-lint docker-check docker-coverage \
		docker-shell docker-clean preflight pr

# -------------------------------
# 🧰 Default and Help Targets
# -------------------------------

default: preflight venv help

help:
	@echo ""
	@echo "🧰  Environment ready. Available targets:"
	@echo ""
	@echo " 🧰 Tooling"
	@echo "    make preflight        → Rerun check for docker, make, gh, thrift"
	@echo "    make venv             → Rerun venv dep check"
	@echo ""
	@echo " 👩‍💻 Local development:"
	@echo "    make test             → Run pytest in local venv"
	@echo "    make lint             → Run pylint on src and tests"
	@echo "    make check            → Run mypy static type checker"
	@echo "    make format           → Auto-format code using black"
	@echo "    make coverage         → Run tests with coverage, generate HTML + badge"
	@echo "    make clean|dist-clean → Different levels of cleanliness"
	@echo ""
	@echo " 🐳 Dockerized workflow:"
	@echo "    make docker-build     → Build Docker image with venv + dev tools"
	@echo "    make docker-test      → Run tests inside Docker using Makefile"
	@echo "    make docker-lint      → Lint code inside Docker container"
	@echo "    make docker-check     → Run mypy type checks inside container"
	@echo "    make docker-coverage  → Run coverage report + badge inside container"
	@echo "    make docker-shell     → Interactive shell inside the dev container"
	@echo "    make docker-clean     → Remove docker artifacts"
	@echo ""
	@echo " 🔁 GitHub Integration:"
	@echo "    make pr               → Push current branch and open a GitHub pull request"
	@echo ""

# -------------------------------
# 🛠️  Virtualenv Setup
# -------------------------------

venv: ensure-env ensure-deps ensure-thrift
	@echo "✅ venv complete"

ensure-env:
	@test -d $(VENV) || { \
		echo "🐍 Creating virtual environment..."; \
		python3 -m venv $(VENV); \
		$(PIP) install -U pip; \
	}

ensure-thrift: $(THRIFT_GEN_DIR)/common $(THRIFT_GEN_DIR)/encoding
	@echo "✅ IDL python complete"

ensure-thrift-gen-py:
	@test -d $(THRIFT_GEN_DIR) || { \
		echo "🧰 creating gen-py for python IDL files"; \
		mkdir $(THRIFT_GEN_DIR); \
	}

$(THRIFT_GEN_DIR)/common: ensure-thrift-gen-py
	@echo "🧰 generating python code from common.thrift IDL"
	@$(THRIFT) --gen py --out $(THRIFT_GEN_DIR) $(THRIFT_IDL_DIR)/common.thrift

$(THRIFT_GEN_DIR)/encoding: ensure-thrift-gen-py
	@echo "🧰 generating python code from encoding.thrift IDL"
	@$(THRIFT) --gen py -I ${THRIFT_IDL_DIR} --out $(THRIFT_GEN_DIR) $(THRIFT_IDL_DIR)/encoding.thrift
	
ensure-deps:
	@$(PYTHON) -c "import pytest, pylint, black, mypy, thrift" 2>/dev/null || { \
		echo '📦 Installing dev dependencies...'; \
		$(PIP) install -e .[dev]; \
	}
	@echo "✅ dependencies complete"

# -------------------------------
# 🧪 Core Tasks
# -------------------------------

test: venv
	$(PYTEST)

lint: venv
	$(PYLINT) src tests

format: venv
	$(BLACK) src tests

check: lint
	$(MYPY) src tests

coverage: venv
	$(COVERAGE) run -m pytest
	$(COVERAGE) report
	$(COVERAGE) xml
	$(COVERAGE) html
	$(VENV)/bin/coverage-badge -o coverage.svg -f

clean:
	@echo "🧹 cleaning build artifacts"
	@echo "🧹 1️⃣ directories"
	@find . \
		-type d \
			\(	\
				-name .pytest_cache -o \
				-name .mypy_cache -o \
				-name htmlcov -o \
				-name build -o \
				-name dist -o \
				-name .venv -o \
				-name '*.egg-info' -o \
				-name gen-py \
			\) \
		-prune -exec sh -c 'echo "\t💥 $$1"; rm -rf -- "$$1"' _ {} \;
	@echo "🧹 2️⃣ files"
	@find . \
		-type f \
			\( \
				-name .coverage -o \
				-name coverage.svg -o \
				-name results.xml \
			\) \
		-exec sh -c 'echo "\t💥 $$1"; rm -f -- "$$1"' _ {} \;
	@echo "✅ tree clean"

dist-clean: clean docker-clean
	@echo "🧼 sparkly clean"

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

docker-clean:
	@echo "🧹 cleaning docker artifacts"
	@docker image rm ${IMAGE_NAME} --force 2>/dev/null
	@echo "✅ docker clean"

# -------------------------------
# 🚦 Preflight Checks
# -------------------------------

preflight:
	@echo "🚦 Running preflight checks..."

	@command -v make >/dev/null 2>&1 || { \
		echo "❌ Preflight failed."; \
		echo "   'make' is required but not installed."; exit 1; \
	}

	@command -v docker >/dev/null 2>&1 || { \
		echo "❌ Preflight failed."; \
		echo "   'docker' is required but not installed."; exit 1; \
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
			echo "❌ Preflight failed."; \
			echo "   Cannot install 'gh' automatically on this platform."; \
			exit 1; \
		fi; \
	}

	@command -v thrift >/dev/null 2>&1 || { \
		echo "🔍 'thrift' (Apache Thrift Compiler) not found. Attempting to install..."; \
		if command -v brew >/dev/null 2>&1; then \
			brew install thrift; \
		elif command -v apt >/dev/null 2>&1; then \
			sudo apt update && sudo apt install -y thrift-compiler; \
		elif command -v dnf >/dev/null 2>&1; then \
			sudo dnf install -y thrift-compiler; \
		else \
			echo "❌ Preflight failed."; \
			echo "   Cannot install 'thrift' automatically on this platform."; \
			exit 1; \
		fi; \
	}

	@echo "✅ preflight complete."

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
