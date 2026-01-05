#\!/bin/bash

# StatShark Local Development Stop Script

echo "🛑 Stopping StatShark local development server..."
docker-compose down

echo ""
echo "✅ Server stopped"
echo ""
echo "To start again: ./start-local.sh"
