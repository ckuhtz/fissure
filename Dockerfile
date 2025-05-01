# Stage 1: Build
FROM python:3.11-slim AS builder

WORKDIR /app

# Install system dependencies (optional but common)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
 && rm -rf /var/lib/apt/lists/*

# Create virtualenv in an isolated path
RUN python -m venv /opt/venv

# Upgrade pip in the venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --upgrade pip

# Copy only files needed to install dependencies (to cache pip layer)
COPY pyproject.toml ./

# Install dev dependencies
RUN pip install -e .[dev]

# Copy full project source
COPY . .

# Run tests in builder (optional)
# RUN make test

# Stage 2: Final minimal image (if needed for runtime)
FROM python:3.11-slim

WORKDIR /app

# Copy virtualenv from builder stage
COPY --from=builder /opt/venv /opt/venv

# Copy project source (if needed for runtime)
COPY --from=builder /app /app

# Activate venv
ENV PATH="/opt/venv/bin:$PATH"

# Default CMD (can be overridden)
CMD ["make", "test"]