# ---------- Stage 1: Builder ----------
FROM python:3.10-slim AS builder

# Install build tools & dependencies
RUN apt-get update && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    ffmpeg \
    bash \
    fastfetch \
    gnupg2 \
    lsb-release \
    ca-certificates \
    build-essential \
 && git clone https://github.com/dylanaraps/neofetch.git /opt/neofetch \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements first for caching
COPY requirements.txt .

# Build wheels for dependencies
RUN pip3 install --upgrade pip wheel \
 && pip3 wheel --no-cache-dir --wheel-dir /app/wheels -r requirements.txt


# ---------- Stage 2: Final ----------
FROM python:3.10-slim

# Install only runtime dependencies (no git here)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    bash \
    fastfetch \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy neofetch from builder
COPY --from=builder /opt/neofetch /opt/neofetch
RUN ln -s /opt/neofetch/neofetch /usr/bin/neofetch

# Copy built wheels and install
COPY --from=builder /app/wheels /wheels
RUN pip3 install --no-cache /wheels/*

# Copy project files
COPY . .

EXPOSE 5000

# Run flask + main.py
CMD flask run -h 0.0.0.0 -p 5000 & python3 main.py
