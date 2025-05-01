FROM python:3.13-slim AS builder

WORKDIR /app

# ✅ Install make and build essentials
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential make && \
    rm -rf /var/lib/apt/lists/*

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY pyproject.toml ./
RUN pip install -U pip
RUN pip install -e .[dev]

COPY . .