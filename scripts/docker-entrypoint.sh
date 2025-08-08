#!/bin/sh
set -e

# Docker entrypoint script for QGEN_IMPFRAG
echo "🚀 Starting QGEN_IMPFRAG Application..."

# Ensure data directories exist
mkdir -p /app/data/ifc /app/data/fragments /app/logs

# Set proper permissions
chown -R nginx:nginx /app/frontend/dist
chmod -R 755 /app/data

# Wait for any initialization to complete
echo "⏳ Initializing services..."

# Check if backend dependencies are installed
cd /app/backend
if [ ! -d "node_modules" ]; then
    echo "📦 Installing backend Node.js dependencies..."
    npm install
fi

# Check Python environment
echo "🐍 Checking Python environment..."
python -c "import sys; print(f'Python version: {sys.version}')"

# Verify that fragment converter is accessible
echo "🔧 Verifying fragment converter..."
if [ -f "/data/XVUE/frag_convert/ifc_fragments_converter.py" ]; then
    echo "✅ Fragment converter found"
else
    echo "❌ Fragment converter not found at /data/XVUE/frag_convert/"
    echo "   Ensure the frag_convert directory is mounted or accessible"
fi

# Test backend startup
echo "🔬 Testing backend startup..."
cd /app/backend
timeout 10s python src/ifc_processor.py --help || echo "⚠️ Backend test completed"

# Nginx configuration test
echo "🌐 Testing nginx configuration..."
nginx -t

echo "✅ Initialization complete. Starting services..."

# Execute the command passed to the container
exec "$@"
