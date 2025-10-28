# My Rails API

Rails 8.0.3 API application with MySQL 8.0, Docker, and AWS deployment.

## Tech Stack

- Ruby 3.3.4
- Rails 8.0.3
- MySQL 8.0
- Docker & Docker Compose
- AWS (ECS, RDS, ECR)
- Terraform
- GitHub Actions CI/CD

## Development Setup

### Prerequisites

- Docker Desktop
- Git

### Getting Started

1. Clone the repository:

```bash
git clone <your-repo-url>
cd my-rails-api
```

2. Copy environment file:

```bash
cp .env.example .env
```

3. Build and start containers:

```bash
docker-compose build
docker-compose up -d
```

4. Create database:

```bash
docker-compose exec web rails db:create db:migrate db:seed
```

5. Access the application:

- API: http://localhost:3000
- Health check: http://localhost:3000/health

## API Endpoints

### Health Check

```
GET /health
```

### Posts API

```
GET    /api/v1/posts       # List all posts
GET    /api/v1/posts/:id   # Get single post
POST   /api/v1/posts       # Create post
PATCH  /api/v1/posts/:id   # Update post
DELETE /api/v1/posts/:id   # Delete post
```

## Docker Commands

```bash
# Build containers
docker-compose build

# Start containers
docker-compose up -d

# Stop containers
docker-compose down

# View logs
docker-compose logs -f web

# Run Rails commands
docker-compose exec web rails console
docker-compose exec web rails db:migrate
```

## Deployment

Deployed to AWS using Terraform and GitHub Actions.

Region: Singapore (ap-southeast-1)
