#!/bin/bash

# Lyo Learning System Setup Script
# This script sets up the complete learning system backend

set -e  # Exit on error

echo "🚀 Lyo Learning System Setup"
echo "================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Check if Docker is running
check_docker() {
    print_info "Checking Docker..."
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker Desktop and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Start Docker services
start_services() {
    print_info "Starting Docker services..."
    docker-compose up -d postgres redis

    # Wait for PostgreSQL to be ready
    print_info "Waiting for PostgreSQL to be ready..."
    sleep 5

    until docker-compose exec -T postgres pg_isready -U lyoapp -d lyoapp_dev > /dev/null 2>&1; do
        echo -n "."
        sleep 1
    done
    echo ""
    print_success "PostgreSQL is ready"
}

# Run Alembic migrations
run_migrations() {
    print_info "Running Alembic migrations..."

    # Install dependencies if needed
    if [ ! -d ".venv" ]; then
        print_info "Creating virtual environment..."
        python3 -m venv .venv
        source .venv/bin/activate
        pip install -r requirements.txt 2>/dev/null || pip install poetry && poetry install
    else
        source .venv/bin/activate
    fi

    # Run migrations
    alembic upgrade head

    if [ $? -eq 0 ]; then
        print_success "Migrations completed successfully"
    else
        print_error "Migration failed"
        exit 1
    fi
}

# Seed course data
seed_data() {
    print_info "Seeding CSS Flexbox course..."

    source .venv/bin/activate
    python3 src/learning/seed/seed_css_flexbox.py

    if [ $? -eq 0 ]; then
        print_success "Seed data loaded successfully"
    else
        print_error "Seeding failed"
        exit 1
    fi
}

# Start backend server
start_backend() {
    print_info "Starting FastAPI backend..."
    docker-compose up -d backend

    # Wait for backend to be ready
    print_info "Waiting for backend to be ready..."
    sleep 5

    until curl -s http://localhost:8000/health > /dev/null 2>&1; do
        echo -n "."
        sleep 1
    done
    echo ""
    print_success "Backend is ready"
}

# Test endpoints
test_endpoints() {
    print_info "Testing API endpoints..."

    # Test health endpoint
    if curl -s http://localhost:8000/health | grep -q "healthy"; then
        print_success "Health check passed"
    else
        print_error "Health check failed"
        return 1
    fi

    # Test docs endpoint
    if curl -s http://localhost:8000/docs > /dev/null 2>&1; then
        print_success "API docs accessible at http://localhost:8000/docs"
    fi
}

# Main execution
main() {
    echo ""
    print_info "Step 1/6: Checking Docker"
    check_docker
    echo ""

    print_info "Step 2/6: Starting services (PostgreSQL, Redis)"
    start_services
    echo ""

    print_info "Step 3/6: Running database migrations"
    run_migrations
    echo ""

    print_info "Step 4/6: Seeding course data"
    seed_data
    echo ""

    print_info "Step 5/6: Starting backend server"
    start_backend
    echo ""

    print_info "Step 6/6: Testing endpoints"
    test_endpoints
    echo ""

    echo "================================"
    print_success "Setup complete!"
    echo ""
    echo "📊 Services running:"
    echo "   - Backend API: http://localhost:8000"
    echo "   - API Docs: http://localhost:8000/docs"
    echo "   - PostgreSQL: localhost:5432"
    echo "   - Redis: localhost:6379"
    echo ""
    echo "🧪 Test the learning system:"
    echo "   1. Open http://localhost:8000/docs"
    echo "   2. Try POST /api/v1/courses/compile"
    echo "   3. Create a session with POST /api/v1/sessions/"
    echo "   4. Connect WebSocket to /api/v1/sessions/{id}/run"
    echo ""
    echo "📝 View logs:"
    echo "   docker-compose logs -f backend"
    echo ""
    echo "🛑 Stop services:"
    echo "   docker-compose down"
    echo ""
}

# Run main function
main
