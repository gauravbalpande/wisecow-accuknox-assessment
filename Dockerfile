# Use Ubuntu as base image
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PORT=4499

# Update package list and install required packages
RUN apt-get update && \
    apt-get install -y \
    fortune-mod \
    cowsay \
    netcat \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create app directory
WORKDIR /app

# Copy the wisecow script
COPY wisecow.sh .

# Make the script executable
RUN chmod +x wisecow.sh

# Create a non-root user for security
RUN useradd -m -u 1001 wisecow && \
    chown -R wisecow:wisecow /app

# Switch to non-root user
USER wisecow

# Expose the default port
EXPOSE 4499

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD nc -z localhost $PORT || exit 1

# Run the application
CMD ["./wisecow.sh", "start"]
