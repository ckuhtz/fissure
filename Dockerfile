FROM python:3.13-slim AS builder

# prep system
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        make \
        thrift-compiler \
    && rm -rf /var/lib/apt/lists/*

# create venv inside the container
ENV VENV=/opt/venv
RUN python3 -m venv --copies "$VENV"
ENV PATH="$VENV/bin:$PATH"

# create project dependencies
WORKDIR /app
COPY pyproject.toml .
RUN pip install -U pip && \
    pip install -e .[dev]

# copy rest of source
COPY pyproject.toml .
COPY src/ ./src
COPY spec/ ./spec
COPY tests/ ./tests

# default command
CMD ["bash"]
