# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 语言要求

请始终使用简体中文与我对话，并在回答时保持专业、简洁。

## Project Overview

miniblog-v4 is a modern microservice blog backend API server built with Go, following clean architecture principles. It uses Gin for HTTP routing, GORM for database operations, JWT for authentication, Casbin for authorization, and OpenTelemetry for observability.

## Development Commands

### Build and Development Workflow

```bash
# Install development tools
make deps

# Generate protobuf code
make protoc

# Sync dependencies
make tidy

# Format code
make format

# Generate code (go:generate directives)
make generate

# Build all binaries
make build

# Build specific binary
make build BINS=blog-apiserver

# Run tests with coverage
make test
make cover

# Run linting
make lint

# Build for multiple platforms
make build.multiarch

# Build Docker images
make image

# Build specific Docker image
make image PLATFORM=linux_amd64 VERSION=v1.0.0 IMAGES=blog-apiserver
```

### Local Development

```bash
# Start dependencies (PostgreSQL, Redis, OTEL Collector)
docker compose -f docker-compose.env.yml up -d

# Build and run locally
make build BINS=blog-apiserver
_output/platforms/$(go env GOOS)/$(go env GOARCH)/blog-apiserver --config configs/blog-apiserver.yaml

# Build and run with Docker
make image IMAGES=blog-apiserver
cd build/docker/blog-apiserver
docker compose up -d
```

### Testing

```bash
# Run all tests
make test

# Run tests with coverage
make cover

# Run specific test
go test -v ./internal/apiserver/biz/v1/user/

# Run benchmark tests
go test -bench=. ./...

# Run integration tests (requires running dependencies)
go test -tags=integration ./...
```

## Architecture Overview

The project follows **Clean Architecture** with clear separation of concerns:

### Core Layers

1. **Handler Layer** (`internal/apiserver/handler/`) - HTTP handlers/controllers
2. **Business Logic Layer** (`internal/apiserver/biz/`) - Use cases and business rules
3. **Store Layer** (`internal/apiserver/store/`) - Data access/repositories
4. **Model Layer** (`internal/apiserver/model/`) - GORM entities and data models

### Key Directories

- `cmd/blog-apiserver/` - Main application entry point
- `internal/apiserver/` - Core server implementation (private)
- `pkg/` - Reusable libraries (can be used externally)
- `configs/` - Configuration files
- `build/docker/` - Docker configurations

### Dependency Injection

Uses Google Wire for compile-time dependency injection. See `internal/apiserver/wire.go` for the DI setup.

## Database and Models

### Database Setup

- **Primary**: PostgreSQL (configurable for MySQL, SQLite)
- **Cache**: Redis
- **ORM**: GORM v2 with automatic migrations
- **Connection Pooling**: Configurable max idle/open connections

### Model Location

GORM models are in `internal/apiserver/model/`. The project uses GORM hooks for validation and follows Go naming conventions.

### Migration

Database migrations are handled automatically by GORM AutoMigrate on server startup.

## API Structure

### REST API Design

- Base URL: `http://localhost:5556`
- Health check: `GET /healthz`
- User management: `POST /v1/users`, `POST /login`
- Metrics: `GET /metrics`
- Debug: `/debug/pprof/*`

### Middleware Stack

1. Recovery (panic handling)
2. Request ID tracking
3. CORS
4. Authentication (JWT)
5. Authorization (Casbin RBAC)
6. Metrics collection
7. Distributed tracing

### Authentication/Authorization

- **JWT**: Token-based authentication with configurable expiration
- **Casbin**: RBAC authorization with policy-based access control
- **Middleware**: Automatic token validation and policy enforcement

## Configuration

### Configuration Files

- `configs/blog-apiserver.yaml` - Local development
- `configs/blog-apiserver.docker.yaml` - Docker development
- `configs/blog-apiserver.prod.yaml.example` - Production template

### Key Configuration Sections

```yaml
addr: 0.0.0.0:5556          # Server address
timeout: 30s                # Request timeout
jwt-key: [secret]           # JWT signing key
expiration: 7d              # Token expiration
otel:                       # OpenTelemetry config
  endpoint: 127.0.0.1:4327
  service-name: blog-apiserver
postgresql:                 # Database config
  host: localhost
  port: 54321
  dbname: miniblog
redis:                      # Redis config
  addr: 127.0.0.1:56379
```

## Code Generation

### Protocol Buffers

```bash
# Generate gRPC and protobuf code
make protoc

# Manual generation
protoc --proto_path=pkg/api --go_out=. --go-grpc_out=. pkg/api/**/*.proto
```

### Dependency Injection

```bash
# Generate Wire code
go generate ./internal/apiserver/
```

## Testing Strategy

### Current State

- Test coverage is currently low (target: 1% in Makefile)
- Focus on adding unit tests for business logic (`biz/` layer)
- Integration tests require running dependencies

### Test Organization

- Unit tests: `*_test.go` files alongside source code
- Integration tests: Use `-tags=integration`
- Example tests: `*_example_test.go` files

## Observability

### OpenTelemetry Integration

- Distributed tracing with automatic context propagation
- Metrics collection for Prometheus
- Structured logging with slog
- Request ID tracking across components

### Key Endpoints

- `/metrics` - Prometheus metrics
- `/debug/pprof/` - Go profiling
- Health checks with detailed status

## Deployment

### Docker Support

- Multi-stage Dockerfile for minimal image size
- Docker Compose for local development
- Production-ready configurations with resource limits

### Port Mappings

- blog-apiserver: 5556 (host) → 5556 (container)
- PostgreSQL: 54321 (host) → 5432 (container)
- Redis: 56379 (host) → 6379 (container)
- OTEL Collector: 4327, 4328, 13133 (host)

## Development Guidelines

### Code Organization

- Follow Go project layout standards
- Keep business logic separate from infrastructure concerns
- Use dependency injection for testability
- Implement proper error handling with custom error types

### Best Practices

- Use structured logging with slog
- Implement proper context propagation
- Follow Go naming conventions and idioms
- Write comprehensive tests for business logic
- Use middleware for cross-cutting concerns

### Common Tasks

- Adding new API endpoints: Create handler → biz → store → model
- Database changes: Update model and let GORM AutoMigrate handle schema
- Adding middleware: Register in `internal/apiserver/httpserver.go`
- Configuration changes: Add to options struct and config files

## Key Dependencies

- **gin**: HTTP web framework
- **gorm**: ORM for database operations
- **jwt-go**: JWT token handling
- **casbin**: Authorization framework
- **wire**: Dependency injection
- **otel**: OpenTelemetry observability
- **cobra**: CLI framework
- **viper**: Configuration management
- **protobuf**: API definitions
