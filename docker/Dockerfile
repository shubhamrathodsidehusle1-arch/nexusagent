FROM dart:3.0 AS builder

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy server source
COPY server/ ./

# Get dependencies
RUN dart pub get

# Build
RUN dart compile exe bin/main.dart -o /nexusagent

# Production image
FROM debian:bookworm-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy binary from builder
COPY --from=builder /nexusagent /usr/local/bin/nexusagent

# Copy config
COPY --from=builder /app/config.example.json /app/config.json

# Create user
RUN useradd -m -s /bin/bash nexusagent && \
    chown -R nexusagent:nexusagent /app
USER nexusagent

# Expose port
EXPOSE 3000

# Run
CMD ["nexusagent"]
