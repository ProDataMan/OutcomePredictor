# StatShark NFL Prediction Server - Production Dockerfile
FROM swift:6.0-jammy as build

WORKDIR /app

# Copy package manifest first for dependency caching
COPY Package.swift ./

# Resolve dependencies first (this creates Package.resolved)
RUN swift package resolve

# Copy source code
COPY Sources ./Sources
COPY Tests ./Tests

# Build the application
RUN swift build --configuration release --product nfl-server

# Production stage
FROM swift:6.0-jammy-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libssl3 \
    libicu70 \
    libxml2 \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy the built executable
COPY --from=build /app/.build/release/nfl-server ./nfl-server

# Create non-root user
RUN useradd -m -s /bin/bash appuser
RUN chown -R appuser:appuser /app
USER appuser

# Set environment variables
ENV ENV=production
ENV PORT=8080
ENV HOSTNAME=0.0.0.0

# Health check - simple server check first
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
  CMD curl -f http://localhost:${PORT}/api/v1/teams || exit 1

# Expose port
EXPOSE 8080

# Start the server
CMD ["./nfl-server", "serve", "--hostname", "0.0.0.0", "--port", "8080", "--env", "production"]