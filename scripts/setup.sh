#!/bin/bash
set -e

# Setup script for QGEN_IMPFRAG development environment
echo "🔧 Setting up QGEN_IMPFRAG development environment..."

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js 18+ from https://nodejs.org/"
    exit 1
fi

NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Node.js version 18+ required. Found: $(node --version)"
    exit 1
fi
echo "✅ Node.js $(node --version)"

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found. Please install Python 3.9+"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1-2)
echo "✅ Python $(python3 --version)"

# Check Docker (optional)
if command -v docker &> /dev/null; then
    echo "✅ Docker $(docker --version)"
else
    echo "⚠️ Docker not found. Install Docker for containerization features."
fi

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p data/ifc data/fragments data/reports backend/logs

# Install backend dependencies
echo "📦 Installing backend dependencies..."
cd backend

# Install Node.js dependencies
if [ -f "package.json" ]; then
    npm install
    echo "✅ Backend Node.js dependencies installed"
fi

# Install Python dependencies
if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt
    echo "✅ Backend Python dependencies installed"
fi

cd ..

# Install frontend dependencies
echo "📦 Installing frontend dependencies..."
cd frontend

if [ -f "package.json" ]; then
    npm install
    echo "✅ Frontend dependencies installed"
fi

cd ..

# Install root dependencies
echo "📦 Installing root dependencies..."
if [ -f "package.json" ]; then
    npm install
    echo "✅ Root dependencies installed"
fi

# Create sample IFC file if none exists
if [ ! "$(ls -A data/ifc/ 2>/dev/null)" ]; then
    echo "📋 No IFC files found. Place your IFC files in the data/ifc/ directory to get started."
fi

# Verify fragment converter access
if [ -f "/data/XVUE/frag_convert/ifc_fragments_converter.py" ]; then
    echo "✅ Fragment converter accessible"
else
    echo "⚠️ Fragment converter not found at /data/XVUE/frag_convert/"
    echo "   This is required for IFC to fragments conversion"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "To get started:"
echo "  1. Place IFC files in data/ifc/"
echo "  2. Run: npm run dev (for development)"
echo "  3. Or run: docker-compose up (for containerized)"
echo ""
echo "Access the application at:"
echo "  Frontend: http://localhost:3111"
echo "  Backend API: http://localhost:8000"
echo ""
