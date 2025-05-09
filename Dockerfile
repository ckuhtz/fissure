FROM python:3.13-slim AS builder

WORKDIR /app

RUN apt-get update && \
    apt-get install --yes --no-install-recommends
RUN apt-get install --yes --no-install-recommends build-essential make thrift-compiler
RUN apt-get rm -rf /var/lib/apt/lists/*

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY pyproject.toml ./
RUN pip install -U pip
RUN pip install -e .[dev]

COPY . .