#!/bin/bash
set -e

echo "🚀 Starting QGEN_IMPFRAG in development mode..."

# Check if running in the correct directory
if [ ! -f "package.json" ]; then
    echo "❌ Please run this script from the QGEN_IMPFRAG root directory"
    exit 1
fi

# Ensure directories exist
mkdir -p data/ifc data/fragments backend/logs

# Function to cleanup background processes
cleanup() {
    echo "🛑 Shutting down development servers..."
    jobs -p | xargs -r kill
    exit
}

# Trap SIGINT and SIGTERM
trap cleanup SIGINT SIGTERM

# Start backend in background
echo "🐍 Starting backend server..."
cd backend
python3 src/ifc_processor.py --dev --watch &
BACKEND_PID=$!
cd ..

# Wait a moment for backend to start
sleep 3

# Start frontend in background
echo "🌐 Starting frontend development server..."
cd frontend
npm run dev &
FRONTEND_PID=$!
cd ..

echo ""
echo "🎉 Development servers started!"
echo ""
echo "📋 Access points:"
echo "  Frontend: http://localhost:3111"
echo "  Backend:  http://localhost:8000"
echo ""
echo "📁 To add IFC files:"
echo "  1. Copy IFC files to: $(pwd)/data/ifc/"
echo "  2. They will be automatically detected and converted"
echo ""
echo "Press Ctrl+C to stop all servers"
echo ""

# Show logs from both servers
echo "📋 Monitoring logs (Ctrl+C to stop)..."

# Wait for background processes
wait
