#!/bin/bash
set -e

echo "🔨 Building QGEN_IMPFRAG Application..."

# Build backend
echo "🐍 Building backend..."
cd backend

# Install Node.js dependencies for fragment conversion
npm install

# Compile Python modules (check syntax)
python3 -m py_compile src/*.py
echo "✅ Backend built successfully"

cd ..

# Build frontend
echo "🌐 Building frontend..."
cd frontend

# Install dependencies and build
npm install
npm run build

echo "✅ Frontend built successfully"
cd ..

# Build Docker images if Docker is available
if command -v docker &> /dev/null; then
    echo "🐳 Building Docker images..."
    
    # Build production image
    docker build -t qgen-impfrag:latest .
    
    echo "✅ Docker images built successfully"
    
    # Show image info
    echo ""
    echo "📋 Built images:"
    docker images | grep qgen-impfrag
else
    echo "⚠️ Docker not available, skipping container build"
fi

echo ""
echo "🎉 Build complete!"
echo ""
echo "To run the application:"
echo "  Development: npm run dev"
echo "  Production:  docker-compose up"
echo ""
