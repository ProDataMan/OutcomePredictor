#\!/bin/bash

# StatShark Local Development Startup Script

set -e

echo "🦈 StatShark Local Development Setup"
echo "===================================="
echo ""

# Check if .env exists
if [ \! -f .env ]; then
    echo "⚠️  .env file not found\!"
    echo ""
    echo "Creating .env from template..."
    cp .env.example .env
    echo ""
    echo "✏️  Please edit .env and add your API keys:"
    echo "   - ODDS_API_KEY"
    echo "   - NEWS_API_KEY (optional)"
    echo "   - API_SPORTS_KEY"
    echo ""
    echo "Then run this script again."
    exit 1
fi

# Check if Docker is running
if \! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running\!"
    echo ""
    echo "Please start Docker Desktop and try again."
    exit 1
fi

echo "✅ Docker is running"
echo ""

# Start containers
echo "🚀 Starting StatShark API server..."
docker-compose up -d

echo ""
echo "⏳ Waiting for server to be ready..."
sleep 5

# Wait for health check
MAX_ATTEMPTS=12
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -sf http://localhost:8080/api/v1/teams > /dev/null 2>&1; then
        echo ""
        echo "✅ API server is ready\!"
        echo ""
        echo "📡 API URL: http://localhost:8080/api/v1"
        echo ""
        echo "🔍 Test endpoints:"
        echo "   curl http://localhost:8080/api/v1/teams"
        echo "   curl http://localhost:8080/api/v1/upcoming"
        echo ""
        echo "📱 iOS: Run app in Xcode (Debug configuration)"
        echo "🤖 Android: Run app in Android Studio (Debug variant)"
        echo ""
        echo "📊 View logs: docker-compose logs -f api"
        echo "🛑 Stop server: docker-compose down"
        exit 0
    fi
    ATTEMPT=$((ATTEMPT + 1))
    echo -n "."
    sleep 5
done

echo ""
echo "❌ Server failed to start within 60 seconds"
echo ""
echo "Check logs:"
echo "   docker-compose logs api"
exit 1
