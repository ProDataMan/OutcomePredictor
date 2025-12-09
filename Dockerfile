# Dockerfile for Azure App Service
# Multi-stage build to minimize image size

# Build stage - Use Swift 6.2 (official release)
FROM swift:6.2 as builder

WORKDIR /app

# Copy package files (but exclude Tests to avoid overlapping sources error)
COPY Package.swift ./
COPY Sources ./Sources

# Build release (only the nfl-server target, skip tests)
RUN swift build -c release --product nfl-server

# Runtime stage - Use Swift 6.2 slim
FROM swift:6.2-slim

WORKDIR /app

# Copy built executable
COPY --from=builder /app/.build/release/nfl-server ./nfl-server

# Azure provides PORT environment variable
ENV PORT=8080
ENV ENV=production

EXPOSE 8080

CMD ["./nfl-server", "serve", "--hostname", "0.0.0.0", "--port", "8080"]
