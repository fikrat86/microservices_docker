# 🌐 Interactive Forum Microservices Dashboard

## Overview
This enhanced version includes a beautiful, interactive web interface that demonstrates real-time communication between distributed microservices.

## 🎯 Features

### Interactive Web Dashboard
- **Real-time Service Status**: Monitor health of all microservices
- **Live Statistics**: See counts for users, threads, and posts
- **Create Content**: Interactive forms to create users, threads, and posts
- **View Data**: Multiple views to see forum activity
- **Inter-Service Communication**: Watch as data flows between services

### Microservices Architecture
1. **Users Service** - Manages user accounts and profiles
2. **Threads Service** - Handles discussion threads
3. **Posts Service** - Manages posts within threads
4. **Nginx Gateway** - Routes requests and serves frontend

## 🚀 Quick Start

### Local Development
```powershell
# Start all services
docker-compose up --build

# Access the dashboard
Start-Process http://localhost:8080
```

### AWS Deployment
The application is deployed on AWS with:
- **ECS Fargate**: Runs containerized microservices
- **Application Load Balancer**: Routes traffic to services
- **DynamoDB**: Stores data with global tables for DR
- **Multi-Region**: Active in us-east-1 and us-west-2

Access URL:
```
http://forum-microservices-alb-dev-1098207024.us-east-1.elb.amazonaws.com
```

## 📊 Usage Scenario

### Scenario: Creating a Complete Forum Thread

1. **Create Users** (Tab: User)
   - Username: `john_doe`
   - Email: `john@example.com`
   - Name: `John Doe`
   
   - Username: `jane_smith`
   - Email: `jane@example.com`
   - Name: `Jane Smith`

2. **Create a Thread** (Tab: Thread)
   - User: Select `John Doe`
   - Title: `Welcome to the Forum!`
   - Category: `General Discussion`

3. **Add Posts** (Tab: Post)
   - User: Select `Jane Smith`
   - Thread: Select `Welcome to the Forum!`
   - Content: `Thanks for creating this thread! Excited to be here.`
   
   - User: Select `John Doe`
   - Thread: Select `Welcome to the Forum!`
   - Content: `Great to have you here, Jane!`

4. **View Results**
   - Switch to "Full View" tab
   - See the complete thread with all posts
   - Watch statistics update in real-time

## 🔄 Inter-Service Communication Flow

```
User Browser
    ↓
NGINX Gateway (Port 80/8080)
    ↓
┌─────────────┬──────────────┬──────────────┐
│             │              │              │
Users API     Threads API    Posts API
(Port 3000)   (Port 3000)    (Port 3000)
│             │              │              │
└─────────────┴──────────────┴──────────────┘
```

### API Endpoints

**Users Service** (`/api/users`)
- `GET /` - List all users
- `POST /` - Create new user
- `GET /:userId` - Get user by ID
- `GET /health` - Health check

**Threads Service** (`/api/threads`)
- `GET /` - List all threads
- `POST /` - Create new thread
- `GET /:threadId` - Get thread by ID
- `GET /health` - Health check

**Posts Service** (`/api/posts`)
- `GET /` - List all posts
- `POST /` - Create new post
- `GET /:postId` - Get post by ID
- `GET /in-thread/:threadId` - Get posts in a thread
- `GET /by-user/:userId` - Get posts by user
- `GET /health` - Health check

## 🎨 Frontend Features

### Dashboard Components
- **Service Status Cards**: Real-time health monitoring with online/offline indicators
- **Statistics Display**: Live counts of users, threads, and posts
- **Tabbed Interface**: Easy navigation between create and view modes
- **Responsive Design**: Works on desktop, tablet, and mobile
- **Beautiful UI**: Modern gradient design with smooth animations

### Data Flow
1. Frontend calls `/api/users` to get all users
2. Frontend calls `/api/threads` to get all threads
3. Frontend calls `/api/posts` to get all posts
4. JavaScript correlates data to show:
   - Which user created which thread
   - How many posts each user has made
   - Complete conversation threads with nested posts

## 🛠️ Technical Details

### Technologies
- **Frontend**: Pure HTML5, CSS3, JavaScript (no frameworks)
- **Backend**: Node.js with Koa.js framework
- **Gateway**: Nginx reverse proxy
- **Data**: In-memory JSON (development) / DynamoDB (production)
- **Containerization**: Docker & Docker Compose

### Configuration Files
- `frontend/index.html` - Interactive dashboard
- `nginx/nginx.conf` - API gateway routing
- `Dockerfile.nginx` - Combined nginx + frontend container
- `docker-compose.yml` - Local orchestration
- `terraform/` - AWS infrastructure as code

## 📈 Monitoring

### Health Checks
All services expose `/health` endpoint returning:
```json
{
  "status": "healthy",
  "service": "users-service",
  "timestamp": "2025-11-27T16:00:00.000Z"
}
```

### Service Discovery
Frontend automatically detects service availability and updates status indicators:
- 🟢 Green: Service is online and responding
- 🔴 Red: Service is offline or unreachable

## 🔐 Security Features
- CORS enabled for cross-origin requests
- Request/response logging
- Error handling middleware
- Health check endpoints for monitoring

## 📝 Data Models

### User
```json
{
  "userId": "uuid-v4",
  "username": "string",
  "email": "string",
  "name": "string",
  "createdAt": "ISO-8601"
}
```

### Thread
```json
{
  "threadId": "uuid-v4",
  "userId": "uuid-v4",
  "title": "string",
  "category": "general|tech|help|announcement",
  "createdAt": "ISO-8601"
}
```

### Post
```json
{
  "postId": "uuid-v4",
  "userId": "uuid-v4",
  "threadId": "uuid-v4",
  "content": "string",
  "createdAt": "ISO-8601"
}
```

## 🧪 Testing

### Manual Testing
1. Open dashboard in browser
2. Create test data using forms
3. Verify data appears in view tabs
4. Check service status indicators
5. Refresh to see data persistence

### API Testing
```powershell
# Test users service
Invoke-WebRequest -Uri "http://localhost:8080/api/users" -Method GET

# Create user
$userData = @{username="test"; email="test@example.com"; name="Test User"} | ConvertTo-Json
Invoke-WebRequest -Uri "http://localhost:8080/api/users" -Method POST -Body $userData -ContentType "application/json"

# Test threads service
Invoke-WebRequest -Uri "http://localhost:8080/api/threads" -Method GET

# Test posts service
Invoke-WebRequest -Uri "http://localhost:8080/api/posts" -Method GET
```

## 🚀 Deployment

### Local
```powershell
docker-compose up --build
```

### AWS (Already Deployed)
Infrastructure is managed by Terraform and deployed via GitHub Actions:
- Push to `main` branch triggers infrastructure workflow
- Infrastructure creates ECS services, ALB, DynamoDB tables
- Microservices workflow builds and deploys Docker images to ECR
- Services automatically register with load balancer

## 📦 Project Structure
```
.
├── frontend/
│   ├── index.html          # Interactive dashboard
│   └── Dockerfile          # Frontend container
├── nginx/
│   └── nginx.conf          # API gateway configuration
├── users/
│   ├── server.js           # Users microservice
│   ├── package.json        # Dependencies
│   └── Dockerfile          # Container image
├── threads/
│   ├── server.js           # Threads microservice
│   ├── package.json        # Dependencies
│   └── Dockerfile          # Container image
├── posts/
│   ├── server.js           # Posts microservice
│   ├── package.json        # Dependencies
│   └── Dockerfile          # Container image
├── terraform/              # AWS infrastructure
├── .github/workflows/      # CI/CD pipelines
├── docker-compose.yml      # Local orchestration
└── Dockerfile.nginx        # Nginx + frontend image
```

## 🎯 Next Steps

1. **Data Persistence**: Connect to DynamoDB for production
2. **Authentication**: Add user login and JWT tokens
3. **WebSockets**: Real-time updates without refresh
4. **Search**: Add full-text search across threads and posts
5. **Moderation**: Admin tools for managing content
6. **Analytics**: Track user engagement and activity

## 📚 Learning Outcomes

This project demonstrates:
- ✅ Microservices architecture
- ✅ API gateway pattern
- ✅ Service-to-service communication
- ✅ Container orchestration
- ✅ RESTful API design
- ✅ Frontend-backend integration
- ✅ Health monitoring
- ✅ CI/CD pipelines
- ✅ Infrastructure as Code
- ✅ Cloud-native deployment

Enjoy exploring the interactive microservices dashboard! 🚀
