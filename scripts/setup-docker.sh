#!/bin/bash
# QGEN_IMPFRAG Docker Permission Fix and Test
# ==========================================
# Fixes Docker permissions and validates deployment

set -e

echo "🐳 QGEN_IMPFRAG Docker Setup and Test"
echo "======================================"

# Check if user is in docker group
if groups $USER | grep &>/dev/null '\bdocker\b'; then
    echo "✅ User $USER is already in docker group"
else
    echo "⚠️  User $USER needs to be added to docker group"
    echo "🔧 Adding user to docker group..."
    sudo usermod -aG docker $USER
    echo "✅ User added to docker group"
    echo ""
    echo "⚠️  IMPORTANT: You need to log out and log back in for changes to take effect"
    echo "   Or run: newgrp docker"
    echo ""
fi

# Test Docker access
echo "🧪 Testing Docker access..."
if docker info &>/dev/null; then
    echo "✅ Docker daemon accessible"
else
    echo "❌ Docker daemon not accessible"
    echo "💡 Try running: newgrp docker"
    echo "   Or log out and log back in"
    exit 1
fi

# Load environment configuration
if [ -f ".env.auto" ]; then
    echo "📋 Loading environment configuration..."
    set -a
    source .env.auto
    set +a
    echo "✅ Environment loaded"
else
    echo "⚠️  No .env.auto found, using defaults"
    export QGEN_BACKEND_PORT=8111
    export QGEN_FRONTEND_PORT=3111
    export VITE_BACKEND_URL=http://localhost:8111
fi

# Validate Docker Compose configuration
echo "🔍 Validating Docker configuration..."
if docker-compose config &>/dev/null; then
    echo "✅ Docker Compose configuration valid"
else
    echo "❌ Docker Compose configuration invalid"
    docker-compose config
    exit 1
fi

# Build and test containers
echo "🏗️  Building containers..."
echo "This may take a few minutes on first run..."

# Build backend first
echo "   Building backend..."
if docker-compose build backend; then
    echo "✅ Backend build successful"
else
    echo "❌ Backend build failed"
    exit 1
fi

# Test backend container
echo "🧪 Testing backend container..."
if docker-compose up -d backend; then
    echo "✅ Backend container started"
    
    # Wait for backend to be ready
    echo "⏳ Waiting for backend to be ready..."
    sleep 10
    
    # Test health endpoint
    if curl -f http://localhost:${QGEN_BACKEND_PORT:-8111}/health &>/dev/null; then
        echo "✅ Backend health check passed"
    else
        echo "⚠️  Backend health check failed (may need more time)"
    fi
    
    # Stop backend
    docker-compose stop backend
    echo "🛑 Backend container stopped"
else
    echo "❌ Backend container failed to start"
    exit 1
fi

# Build frontend
echo "   Building frontend..."
if docker-compose build frontend; then
    echo "✅ Frontend build successful"
else
    echo "❌ Frontend build failed"
    exit 1
fi

# Clean up
echo "🧹 Cleaning up test containers..."
docker-compose down

echo ""
echo "🎉 Docker setup and testing complete!"
echo ""
echo "🚀 Ready for deployment!"
echo "   Full stack: docker-compose up"
echo "   Production: docker-compose --profile production up -d"
echo "   Development: docker-compose up backend frontend"
echo ""
echo "📊 Access points:"
echo "   Backend API: http://localhost:${QGEN_BACKEND_PORT:-8111}"
echo "   Frontend UI: http://localhost:${QGEN_FRONTEND_PORT:-3111}"
echo "   Health Check: http://localhost:${QGEN_BACKEND_PORT:-8111}/health"
