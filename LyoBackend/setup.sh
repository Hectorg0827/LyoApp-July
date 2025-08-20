#!/bin/bash

# LyoApp Backend Setup Script
# This script sets up the complete backend environment

set -e

echo "🚀 LyoApp Backend Setup Starting..."

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

# Check if Python 3.8+ is installed
check_python() {
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
        print_status "Found Python $PYTHON_VERSION"
        
        if python3 -c 'import sys; exit(0 if sys.version_info >= (3, 8) else 1)'; then
            print_success "Python version check passed"
        else
            print_error "Python 3.8+ required, found $PYTHON_VERSION"
            exit 1
        fi
    else
        print_error "Python 3 not found. Please install Python 3.8+"
        exit 1
    fi
}

# Check if PostgreSQL is running
check_postgresql() {
    if command -v psql &> /dev/null; then
        print_status "PostgreSQL client found"
        
        # Try to connect to default database
        if pg_isready -q; then
            print_success "PostgreSQL server is running"
            
            # Check if lyoapp database exists
            if psql -lqt | cut -d \| -f 1 | grep -qw lyoapp_dev; then
                print_success "Database 'lyoapp_dev' already exists"
            else
                print_status "Creating database 'lyoapp_dev'..."
                createdb lyoapp_dev || print_warning "Could not create database (may already exist)"
            fi
        else
            print_warning "PostgreSQL server not running. Please start PostgreSQL."
            print_status "On macOS with Homebrew: brew services start postgresql"
            print_status "On Ubuntu: sudo systemctl start postgresql"
        fi
    else
        print_warning "PostgreSQL not found. Please install PostgreSQL 13+"
    fi
}

# Check if Redis is running
check_redis() {
    if command -v redis-cli &> /dev/null; then
        print_status "Redis client found"
        
        if redis-cli ping | grep -q "PONG"; then
            print_success "Redis server is running"
        else
            print_warning "Redis server not running. Please start Redis."
            print_status "On macOS with Homebrew: brew services start redis"
            print_status "On Ubuntu: sudo systemctl start redis"
        fi
    else
        print_warning "Redis not found. Please install Redis 6+"
    fi
}

# Install Python dependencies
install_dependencies() {
    print_status "Installing Python dependencies..."
    
    if command -v pip3 &> /dev/null; then
        pip3 install -r requirements.txt
        print_success "Dependencies installed successfully"
    else
        print_error "pip3 not found. Please install pip."
        exit 1
    fi
}

# Create environment file
create_env_file() {
    if [ ! -f .env ]; then
        print_status "Creating .env file..."
        
        # Generate random secret key
        SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_urlsafe(32))')
        JWT_SECRET=$(python3 -c 'import secrets; print(secrets.token_urlsafe(32))')
        
        cat > .env << EOF
# Environment Configuration
ENVIRONMENT=development

# Database Configuration
DATABASE_URL=postgresql+asyncpg://postgres:password@localhost:5432/lyoapp_dev
DATABASE_URL_SYNC=postgresql://postgres:password@localhost:5432/lyoapp_dev

# Redis Configuration
REDIS_URL=redis://localhost:6379/0

# Security
SECRET_KEY=$SECRET_KEY
JWT_SECRET_KEY=$JWT_SECRET
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30
JWT_REFRESH_TOKEN_EXPIRE_DAYS=7

# CORS Settings
BACKEND_CORS_ORIGINS=["http://localhost:3000","http://localhost:8080","http://localhost:8000"]

# Rate Limiting
RATE_LIMIT_ENABLED=true

# Google Cloud Storage (Optional - for production)
# GCS_BUCKET_NAME=lyoapp-media
# GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json

# External APIs (Optional)
# OPENAI_API_KEY=your_openai_api_key_here

# Email Configuration (Optional)
# SMTP_HOST=smtp.gmail.com
# SMTP_PORT=587
# SMTP_USERNAME=your_email@gmail.com
# SMTP_PASSWORD=your_app_password

# Apple Sign-In (Optional)
# APPLE_CLIENT_ID=your_apple_client_id
# APPLE_TEAM_ID=your_apple_team_id
# APPLE_KEY_ID=your_apple_key_id
# APPLE_PRIVATE_KEY_PATH=/path/to/apple_private_key.p8
EOF
        
        print_success ".env file created"
        print_warning "Please update the database credentials in .env file"
    else
        print_success ".env file already exists"
    fi
}

# Setup database
setup_database() {
    print_status "Setting up database..."
    
    # Run migrations
    alembic upgrade head
    print_success "Database migrations completed"
    
    # Seed initial data
    print_status "Seeding initial data..."
    python3 seed_data.py
    print_success "Initial data seeded"
}

# Create uploads directory
create_uploads_dir() {
    if [ ! -d "uploads" ]; then
        mkdir -p uploads
        print_success "Uploads directory created"
    else
        print_success "Uploads directory already exists"
    fi
}

# Test the setup
test_setup() {
    print_status "Testing backend setup..."
    
    # Start server in background for testing
    python3 start_dev.py &
    SERVER_PID=$!
    
    # Wait for server to start
    sleep 5
    
    # Test health endpoint
    if curl -s http://localhost:8000/health | grep -q "healthy"; then
        print_success "Backend server is running correctly!"
    else
        print_error "Backend server test failed"
        kill $SERVER_PID 2>/dev/null || true
        exit 1
    fi
    
    # Stop test server
    kill $SERVER_PID 2>/dev/null || true
    sleep 2
}

# Main setup process
main() {
    echo "🔧 Starting LyoApp Backend Setup"
    echo "=================================="
    
    print_status "Step 1/8: Checking Python installation..."
    check_python
    
    print_status "Step 2/8: Checking PostgreSQL..."
    check_postgresql
    
    print_status "Step 3/8: Checking Redis..."
    check_redis
    
    print_status "Step 4/8: Installing dependencies..."
    install_dependencies
    
    print_status "Step 5/8: Creating environment configuration..."
    create_env_file
    
    print_status "Step 6/8: Setting up database..."
    setup_database
    
    print_status "Step 7/8: Creating uploads directory..."
    create_uploads_dir
    
    print_status "Step 8/8: Testing setup..."
    test_setup
    
    echo ""
    echo "🎉 Setup Complete!"
    echo "=================="
    print_success "LyoApp Backend is ready!"
    echo ""
    print_status "Next steps:"
    echo "  1. Review and update .env file if needed"
    echo "  2. Start the development server: python3 start_dev.py"
    echo "  3. Visit http://localhost:8000/docs for API documentation"
    echo ""
    print_status "Available commands:"
    echo "  make dev          - Start development server"
    echo "  make test         - Run tests"
    echo "  make db-reset     - Reset database"
    echo "  make db-seed      - Seed data"
    echo "  make lint         - Run code linting"
    echo ""
}

# Run main function
main
