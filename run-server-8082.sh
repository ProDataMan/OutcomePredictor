#!/bin/bash

# Start the NFL Outcome Predictor Server on port 8085
# (Ports 8080 and 8082 are already in use)

echo "Starting NFL Outcome Predictor Server on port 8085..."
echo "API will be available at: http://localhost:8085"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Run the server with custom port using Vapor's --port flag
swift run nfl-server serve --hostname 0.0.0.0 --port 8085
