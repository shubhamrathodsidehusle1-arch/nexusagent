#!/bin/bash

# NexusAgent Deployment Script

set -e

echo "🚀 NexusAgent Deployment Script"
echo "================================"

# Check for required tools
command -v docker >/dev/null 2>&1 || { echo "Docker is required but not installed. Aborting." >&2; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo "Docker Compose is required but not installed. Aborting." >&2; exit 1; }

# Check for config
if [ ! -f "docker/config.json" ]; then
    echo "📝 Creating config from example..."
    cp server/config.example.json docker/config.json
    echo "⚠️  Please edit docker/config.json with your settings!"
fi

# Check for JWT secret
if [ -z "$NEXUSAGENT_JWT_SECRET" ]; then
    echo "⚠️  NEXUSAGENT_JWT_SECRET not set. Using default (CHANGE IN PRODUCTION!)"
    export NEXUSAGENT_JWT_SECRET="change-me-in-production-$(date +%s)"
fi

# Build Docker image
echo "🔨 Building Docker image..."
cd docker
docker-compose build

# Start services
echo "▶️  Starting services..."
docker-compose up -d

# Wait for healthy
echo "⏳ Waiting for services to be healthy..."
sleep 5

# Check status
echo ""
echo "📊 Service Status:"
docker-compose ps

echo ""
echo "🎉 NexusAgent is running!"
echo ""
echo "   API:        http://localhost:3000"
echo "   Health:     http://localhost:3000/health"
echo ""
echo "📝 Next steps:"
echo "   - Edit docker/config.json with your API keys"
echo "   - Restart: docker-compose restart nexusagent"
echo "   - View logs: docker-compose logs -f nexusagent"
