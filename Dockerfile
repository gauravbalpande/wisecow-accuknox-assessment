# ============================================================
# Stage 1: Builder — install fortune-mod & cowsay, collect bins
# ============================================================
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        fortune-mod \
        cowsay \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# Stage 2: Runtime — minimal Debian slim image
# ============================================================
FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PORT=4499

# Install only the runtime dependencies (python3 for the HTTP server, netcat for healthcheck)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        netcat-openbsd \
        librecode0 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy fortune binary and data files from builder
COPY --from=builder /usr/games/fortune /usr/games/fortune
COPY --from=builder /usr/share/games/fortunes /usr/share/games/fortunes
COPY --from=builder /usr/lib/x86_64-linux-gnu/libfortune* /usr/lib/x86_64-linux-gnu/ 2>/dev/null || true

# Copy cowsay (Perl script + cow files)
COPY --from=builder /usr/games/cowsay /usr/games/cowsay
COPY --from=builder /usr/share/cowsay /usr/share/cowsay

# Add games to PATH so fortune & cowsay are found
ENV PATH="/usr/games:${PATH}"

# Create app directory
WORKDIR /app

# Copy the application script
COPY wisecow.sh .
RUN chmod +x wisecow.sh

# Create a non-root user for security
RUN useradd -m -u 1001 -s /bin/bash wisecow && \
    chown -R wisecow:wisecow /app

# Switch to non-root user
USER wisecow

# Expose the application port
EXPOSE 4499

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD nc -z localhost ${PORT} || exit 1

# Labels for metadata
LABEL maintainer="gauravbalpande" \
      description="Wisecow — Fortune & Cowsay Web Server" \
      version="2.0"

# Run the application
CMD ["./wisecow.sh", "start"]
