# # ============================================================
# Wisecow Dockerfile — Optimized Runtime Image
# ============================================================
FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PORT=4499

# Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        netcat-openbsd \
        fortune-mod \
        fortunes-min \
        cowsay \
    && rm -rf /var/lib/apt/lists/*

# Add games binaries to PATH
ENV PATH="/usr/games:${PATH}"

# Create application directory
WORKDIR /app

# Copy application script
COPY wisecow.sh .

# Make script executable
RUN chmod +x wisecow.sh

# Create non-root user for security
RUN useradd -m -u 1001 -s /bin/bash wisecow && \
    chown -R wisecow:wisecow /app

# Switch to non-root user
USER wisecow

# Expose application port
EXPOSE 4499

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD nc -z localhost ${PORT} || exit 1

# Metadata labels
LABEL maintainer="gauravbalpande" \
      description="Wisecow — Fortune & Cowsay Web Server" \
      version="2.1"

# Run the application
CMD ["./wisecow.sh", "start"]