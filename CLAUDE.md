# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

nhaituvung_api is a Rails 8 API for a Japanese language learning application focused on JLPT vocabulary (N1-N5). The application is deployed on AWS ECS Fargate with infrastructure managed via Terraform.

**Tech Stack:**
- Ruby 3.3.4
- Rails 8.0.2
- MySQL 8.0
- Redis (for Sidekiq background jobs)
- Puma web server
- AWS ECS Fargate (production)
- Docker for containerization

## Common Development Commands

### Local Development

```bash
# Start local development environment with Docker Compose
docker-compose up -d

# Stop local environment
docker-compose down

# Run Rails server locally (without Docker)
rails server

# Database operations
rails db:create
rails db:migrate
rails db:seed
rails db:rollback

# Run database operations in Docker
docker-compose exec web rails db:migrate
docker-compose exec web rails db:seed

# Rails console
rails console
# Or in Docker:
docker-compose exec web rails console

# Generate migrations
rails generate migration YourMigrationName

# View logs
docker-compose logs -f web
```

### Code Quality

```bash
# Run Rubocop linter
bin/rubocop

# Run Brakeman security scanner
bin/brakeman

# Fix auto-fixable Rubocop issues
bin/rubocop -a
```

### AWS Deployment

All deployment scripts are in `scripts/` directory:

```bash
# Deploy to AWS ECS (build, push, deploy)
./scripts/deploy.sh

# Get application URL after deployment
./scripts/get-url.sh

# View CloudWatch logs in real-time
./scripts/logs.sh

# Check service status
./scripts/status.sh

# Run migrations on production
./scripts/migrate.sh

# SSH into running container
./scripts/ssh.sh

# Stop service to save costs (scale to 0)
./scripts/stop.sh

# Start service again (scale to 1)
./scripts/start.sh
```

**Important:** The production IP address changes with each deployment. Always run `./scripts/get-url.sh` after deploying.

### Terraform Infrastructure

```bash
# Navigate to production environment
cd terraform/environments/production

# Initialize Terraform
terraform init

# Plan infrastructure changes
terraform plan

# Apply infrastructure changes
terraform apply

# View current infrastructure state
terraform show
```

## Architecture

### Application Structure

- **Controllers**: Located in `app/controllers/api/v1/` - API endpoints are versioned
- **Models**: Located in `app/models/` - ActiveRecord models
- **Jobs**: Located in `app/jobs/` - Sidekiq background jobs
- **Routes**: Defined in `config/routes.rb`

### Infrastructure (AWS)

**Current Setup (Production):**
```
Internet → Dynamic IP:3000 → ECS Fargate Task → RDS MySQL
                                    ↓
                                  Redis
```

**Components:**
- **ECS Cluster**: Runs containerized Rails app on Fargate
- **RDS MySQL**: Managed database service
- **ECR**: Container image registry
- **CloudWatch**: Logging and monitoring
- **VPC**: Network isolation with security groups

**Region:** ap-southeast-1 (Singapore)

### Background Jobs

The application uses **Sidekiq** for background job processing with Redis as the backend.

- **Configuration**: `config/sidekiq.yml`
- **Queues**: default, mailers, active_storage_analysis, active_storage_purge
- **Web UI**: Available at `/sidekiq` (requires session authentication)
- **Concurrency**:
  - Production: 10 workers
  - Development: 2 workers

To run Sidekiq locally:
```bash
bundle exec sidekiq
```

### Database

- **Development**: Uses Docker MySQL container on port 3307
- **Production**: AWS RDS MySQL 8.0
- **Configuration**: Environment-based via `config/database.yml`
- **Required ENV vars**: DB_HOST, DB_USERNAME, DB_PASSWORD, DB_NAME

### API Endpoints

Current endpoints (versioned under `/api/v1`):

- `GET /api/v1/posts` - List all posts
- `GET /api/v1/posts/:id` - Get single post
- `POST /api/v1/posts` - Create post
- `PATCH /api/v1/posts/:id` - Update post
- `DELETE /api/v1/posts/:id` - Delete post

Health check:
- `GET /up` - Rails health check endpoint

## Environment Variables

Required environment variables (see `.env.example`):

```bash
# Database
DB_HOST=localhost
DB_USERNAME=root
DB_PASSWORD=password
DB_NAME=nhaituvung_api_development
DB_PORT=3306

# Redis
REDIS_URL=redis://localhost:6379/0

# Rails
RAILS_ENV=development
RAILS_MAX_THREADS=5
```

## Deployment Workflow

### Standard Deployment

1. Make code changes and commit
2. Run `./scripts/deploy.sh` (builds Docker image, pushes to ECR, deploys to ECS)
3. Wait 30-60 seconds for deployment
4. Get new URL with `./scripts/get-url.sh`
5. Verify with health check: `curl http://<ip>:3000/up`

### Deployment with Migrations

1. Generate migration: `bundle exec rails generate migration YourMigration`
2. Edit migration file
3. Deploy: `./scripts/deploy.sh`
4. Run migration: `./scripts/migrate.sh`
5. Verify with logs: `./scripts/logs.sh`

### Debugging Deployments

```bash
# Check service status
./scripts/status.sh

# View real-time logs
./scripts/logs.sh

# SSH into container for debugging
./scripts/ssh.sh

# Inside container, you can run:
bundle exec rails console
cat log/production.log
ps aux
free -h
```

## Important Notes

- **No test framework configured**: This project currently has no automated tests setup
- **Sidekiq Web UI**: Accessible at `/sidekiq` but requires proper authentication in production
- **Security Groups**: Database is only accessible from ECS tasks, not public internet
- **Cost Optimization**: Use `./scripts/stop.sh` to scale down to 0 tasks when not in use (RDS still incurs charges)
- **Dynamic IP**: Production uses dynamic IP that changes on each deployment. Future enhancement planned for ALB + Route53
- **Container Resources**: Tasks use Fargate with configurable CPU/memory in Terraform

## Documentation References

For more detailed information, see:
- `docs/COMPLETE_GUIDE.md` - Comprehensive guide
- `docs/DEPLOY_GUIDE.md` - Detailed deployment instructions
- `docs/TERRAFORM_GUIDE.md` - Infrastructure as Code guide
- `scripts/README.md` - Detailed script documentation
