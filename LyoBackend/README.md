# LyoApp Backend

Production-ready FastAPI backend for LyoApp - A modular monolith with strict module boundaries designed for Google Cloud Platform.

## 🏗️ Architecture

**Modular Monolith** with the following modules:

- **core** - Configuration, database, logging, utilities
- **auth** - Authentication, authorization, RBAC
- **profiles** - User profiles and social features
- **tutor** - AI tutoring services
- **planner** - Course planning and recommendations
- **practice** - Practice sessions and assessments
- **media** - File upload and media management
- **feeds** - Social feeds and content discovery
- **stories** - 24-hour stories feature
- **community** - Social interactions and following
- **messaging** - Real-time messaging and WebSockets
- **notifications** - Push notifications and alerts
- **moderation** - Content moderation and safety
- **search** - Hybrid search (keyword + semantic)
- **gamification** - XP, achievements, streaks
- **admin** - Administrative tools and moderation

## 🚀 Quick Start

### Prerequisites

- Python 3.11+
- Poetry
- PostgreSQL 15+ with pgvector extension
- Redis
- Docker (optional)

### Development Setup

```bash
# Clone and setup
git clone <repository>
cd LyoBackend

# Install dependencies
make install

# Copy environment variables
cp .env.sample .env
# Edit .env with your configuration

# Run database migrations
make migrate

# Seed development data
make seed

# Start development server
make dev
```

The API will be available at http://localhost:8000

- API Documentation: http://localhost:8000/docs
- Health Check: http://localhost:8000/health

### With Docker

```bash
# Run with docker-compose
make docker-run
```

## 🛠️ Development

### Available Commands

```bash
make help          # Show all available commands
make install       # Install dependencies
make dev           # Run development server
make test          # Run tests with coverage
make lint          # Run linting
make format        # Format code
make type-check    # Run type checking
make self-check    # Run all checks (mandatory after changes)
```

### Code Quality

This project enforces strict code quality standards:

- **Linting**: Ruff for fast Python linting
- **Formatting**: Black for code formatting
- **Type Checking**: MyPy for static type analysis
- **Testing**: Pytest with coverage requirements (≥80%)
- **Security**: Bandit for security analysis

### Mandatory Self-Check

After every change, run:

```bash
make self-check
```

This ensures code quality and validates the service starts correctly.

## 🔐 Authentication & Security

### JWT Authentication

- **Access tokens**: 30-minute expiry
- **Refresh tokens**: 30-day expiry with rotation
- **Token blacklisting**: Immediate revocation support

### RBAC (Role-Based Access Control)

- **student**: Default role, private profiles by default
- **teacher**: Can create courses, moderate content
- **guardian**: Can supervise student accounts
- **admin**: Full administrative access

### Security Features

- Rate limiting (Redis-backed)
- Request ID tracking
- PII redaction in logs
- Security headers
- CORS configuration
- Login attempt tracking

## 🗄️ Database

### PostgreSQL with Extensions

- **pgvector**: For semantic search embeddings
- **UUID**: For primary keys
- **Timezone-aware timestamps**

### Migrations

```bash
make migrate                    # Apply migrations
make migrate-create            # Create new migration
```

## 🎯 API Endpoints

### Authentication (`/v1/auth`)

- `POST /login` - Email/password authentication
- `POST /register` - User registration
- `POST /refresh` - Token refresh
- `POST /apple` - Apple Sign-In
- `POST /logout` - Logout and token revocation
- `GET /me` - Current user info
- `PUT /me` - Update profile

### Health Checks

- `GET /health` - Basic health check
- `GET /health/ready` - Readiness check with dependencies

## 🔧 Configuration

Environment variables (see `.env.sample`):

### Core Settings
```env
DATABASE_URL=postgresql+asyncpg://user:pass@localhost/lyoapp_dev
REDIS_URL=redis://localhost:6379/0
SECRET_KEY=your-secret-key
JWT_SECRET_KEY=your-jwt-secret
```

### Feature Flags
```env
ENABLE_ENHANCED_RANKING=false
ENABLE_EXPLORATION=false
ENABLE_GAMIFICATION=true
```

### Rate Limits
```env
RATE_LIMIT_AUTH=60
RATE_LIMIT_AI=30
RATE_LIMIT_POSTING=20
```

## 🚀 Deployment

### Google Cloud Platform

```bash
# Build and deploy
make deploy
```

### Infrastructure Requirements

- **Cloud Run**: Serverless container platform
- **Cloud SQL**: PostgreSQL with pgvector
- **Memorystore**: Redis instance
- **Cloud Storage**: Media files
- **Secret Manager**: Environment variables
- **Artifact Registry**: Container images

## 📊 Monitoring & Observability

### Structured Logging

- **Request tracking**: Unique request IDs
- **User context**: User ID in all logs
- **PII redaction**: Configurable sensitive data masking
- **JSON format**: Structured logs for analysis

### Health Monitoring

- Database connectivity checks
- Redis connectivity checks
- Dependency health validation

## 🧪 Testing

```bash
make test              # Run all tests
make test-coverage     # Generate coverage report
```

### Test Coverage

Minimum 80% coverage required for:
- Unit tests
- Integration tests
- API endpoint tests

## 🔄 CI/CD Pipeline

### GitHub Actions Pipeline

1. **Lint & Type Check**: Ruff, MyPy validation
2. **Tests**: Pytest with coverage requirements
3. **Security**: Bandit security scanning
4. **Build**: Docker image creation
5. **Deploy**: Google Cloud Run deployment
6. **Smoke Tests**: Post-deployment validation

## 🎮 Features Implemented

### ✅ Core Features

- [x] JWT Authentication with refresh tokens
- [x] RBAC with student/teacher/guardian/admin roles
- [x] Rate limiting and security measures
- [x] Health checks and monitoring
- [x] Structured logging with PII redaction
- [x] Database migrations with Alembic
- [x] Redis integration for caching/queues
- [x] API versioning (`/v1` prefix)

### 🚧 In Progress

- [ ] AI Tutor integration (OpenAI)
- [ ] Media upload with GCS
- [ ] Real-time messaging with WebSockets
- [ ] Social feeds and stories
- [ ] Push notifications
- [ ] Content moderation pipeline
- [ ] Hybrid search (keyword + semantic)
- [ ] Gamification system

### 📋 Planned

- [ ] Apple Sign-In integration
- [ ] Advanced analytics with BigQuery
- [ ] Content recommendation engine
- [ ] Advanced moderation with AI
- [ ] Multi-language support

## 🛡️ Security Considerations

### Data Protection

- **PII Handling**: Automatic redaction in logs
- **Password Security**: Bcrypt hashing with salt
- **Token Security**: Secure random generation
- **Rate Limiting**: Configurable per-endpoint limits

### Content Safety

- **Moderation Pipeline**: Automated content scanning
- **Report System**: User-generated content reporting
- **Privacy Controls**: Private profiles by default
- **Safe Defaults**: Student accounts have restricted DMs

## 📝 Development Guidelines

### Code Style

- **Python**: Follow PEP 8 with Black formatting
- **Imports**: Absolute imports with isort
- **Type Hints**: Required for all public functions
- **Docstrings**: Google style docstrings

### Module Boundaries

- **No cross-module imports** except via service interfaces
- **Dependency injection** for service coupling
- **Clear API contracts** between modules

### Error Handling

- **Structured exceptions** with specific error types
- **Proper HTTP status codes**
- **User-friendly error messages**
- **Comprehensive logging** for debugging

## 📞 Support

For questions, issues, or contributions:

1. Check the API documentation at `/docs`
2. Review the health status at `/health/ready`
3. Check logs for detailed error information
4. Run `make self-check` to validate your setup

## 📄 License

Copyright © 2024 LyoApp. All rights reserved.
