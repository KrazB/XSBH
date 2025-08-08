#!/bin/bash
# QGEN_IMPFRAG Cross-Platform Setup Script
# ========================================
# Automatically configures the application for Linux, Windows, or macOS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to detect operating system
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        CYGWIN*|MINGW*|MSYS*) echo "windows";;
        *)          echo "unknown";;
    esac
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Main setup function
main() {
    print_status "🚀 QGEN_IMPFRAG Cross-Platform Setup"
    echo "======================================"
    
    # Detect operating system
    OS=$(detect_os)
    print_status "Detected OS: $OS"
    
    # Check Python availability
    if command_exists python3; then
        PYTHON_CMD="python3"
    elif command_exists python; then
        PYTHON_CMD="python"
    else
        print_error "Python not found! Please install Python 3.7 or higher"
        exit 1
    fi
    
    print_success "Python found: $PYTHON_CMD"
    
    # Run environment manager
    print_status "Configuring environment..."
    $PYTHON_CMD scripts/environment-manager.py --config
    
    # Generate environment file
    print_status "Generating environment configuration..."
    $PYTHON_CMD scripts/environment-manager.py --env
    
    # Check for Docker
    print_status "Checking Docker availability..."
    if command_exists docker; then
        print_success "Docker is available"
        if command_exists docker-compose; then
            print_success "Docker Compose is available"
        else
            print_warning "Docker Compose not found - Docker stack may not work"
        fi
    else
        print_warning "Docker not found - containerized deployment unavailable"
    fi
    
    # Check Node.js for frontend
    print_status "Checking Node.js for frontend..."
    if command_exists npm; then
        print_success "Node.js/NPM found"
        # Install frontend dependencies
        print_status "Installing frontend dependencies..."
        cd frontend
        npm install
        cd ..
        print_success "Frontend dependencies installed"
    else
        print_warning "Node.js/NPM not found - frontend may not build"
    fi
    
    # Setup Python environment
    print_status "Setting up Python environment..."
    cd backend
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ]; then
        print_status "Creating Python virtual environment..."
        $PYTHON_CMD -m venv venv
    fi
    
    # Activate virtual environment
    if [ "$OS" = "windows" ]; then
        source venv/Scripts/activate
    else
        source venv/bin/activate
    fi
    
    # Install Python dependencies
    print_status "Installing Python dependencies..."
    pip install -r requirements.txt
    
    cd ..
    print_success "Python environment configured"
    
    # Create necessary directories
    print_status "Creating data directories..."
    mkdir -p data/ifc
    mkdir -p data/fragments
    mkdir -p data/reports
    mkdir -p backend/logs
    print_success "Data directories created"
    
    # Final status
    echo ""
    print_success "🎉 QGEN_IMPFRAG setup complete!"
    echo ""
    echo "Next steps:"
    echo "1. Review the generated .env.auto file"
    echo "2. Start the backend: cd backend && python app.py"
    echo "3. Start the frontend: cd frontend && npm run dev"
    echo "4. Or use Docker: docker-compose up"
    echo ""
    echo "For more information, see README.md"
}

# Run main function
main "$@"
