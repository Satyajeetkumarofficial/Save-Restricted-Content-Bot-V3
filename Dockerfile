# ---------- Stage 1: Build dependencies ----------
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
 && ln -s /opt/neofetch/neofetch /usr/bin/neofetch \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Build wheels for dependencies
RUN pip3 install --upgrade pip wheel \
 && pip3 wheel --no-cache-dir --wheel-dir /app/wheels -r requirements.txt


# ---------- Stage 2: Final lightweight image ----------
FROM python:3.10-slim

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    bash \
    fastfetch \
    ca-certificates \
 && git clone https://github.com/dylanaraps/neofetch.git /opt/neofetch \
 && ln -s /opt/neofetch/neofetch /usr/bin/neofetch \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy built wheels and install
COPY --from=builder /app/wheels /wheels
RUN pip3 install --no-cache /wheels/*

# Copy project files
COPY . .

EXPOSE 5000

# Run flask + main.py
CMD flask run -h 0.0.0.0 -p 5000 & python3 main.py
