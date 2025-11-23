# Microservice Communication Dashboard Guide

## Overview
The Microservice Communication Dashboard is an interactive web application that visualizes real-time communication between the three microservices (Users, Posts, and Threads). It provides a live demonstration of how microservices interact with each other.

## Features

### 1. Real-Time Health Monitoring
- Automatic health checks every 30 seconds
- Visual status indicators (Healthy/Unhealthy/Offline)
- Service availability tracking

### 2. Interactive API Testing
- Test individual endpoints with one click
- View real-time responses
- JSON-formatted output display

### 3. Service Communication Demos
Four pre-built demonstration scenarios:

#### Get User with Posts
Demonstrates cascading service calls:
1. Fetch user from Users Service
2. Fetch posts by that user from Posts Service
3. Display combined data

#### Get Thread with Details
Shows complex multi-service interaction:
1. Fetch thread from Threads Service
2. Fetch posts in that thread from Posts Service
3. Fetch author information from Users Service
4. Combine all data

#### Get Posts with Authors
Demonstrates data enrichment:
1. Fetch posts from Posts Service
2. Extract unique user IDs
3. Fetch author details from Users Service
4. Enrich posts with author data

#### Full Service Chain
Complete workflow across all services:
1. Fetch all threads
2. Fetch posts for first thread
3. Fetch all users
4. Show comprehensive system interaction

### 4. Metrics Dashboard
Tracks:
- Total requests made
- Successful requests
- Failed requests
- Average response time

## Accessing the Dashboard

### Local Development

1. **Start Services with Docker Compose**:
```powershell
docker-compose up -d
```

2. **Open Dashboard**:
- Open `dashboard.html` in your browser
- Default configuration points to `http://localhost:8080`

### AWS Deployment

1. **Get ALB DNS**:
```powershell
cd terraform
terraform output alb_dns_name
```

2. **Configure Dashboard**:
- Open `dashboard.html` in browser
- Update the "Load Balancer URL" field with your ALB DNS
- Example: `http://your-alb-123456.us-east-1.elb.amazonaws.com`

3. **Access**:
The dashboard will automatically test all service endpoints using the configured ALB.

## Using the Dashboard

### Configuration Panel

1. **Load Balancer URL**:
   - Enter your ALB or nginx proxy URL
   - Automatically validates on change
   - Saves to local session

### Service Cards

Each microservice has its own card showing:

- **Service Name**: Visual identifier with emoji
- **Status Badge**: Current health status
  - 🟢 Healthy: Service responding normally
  - 🔴 Unhealthy: Service responding with errors
  - ⚫ Offline: Service not responding

- **Endpoints**: List of available API endpoints
  - Click "Test" button to execute
  - Response appears below endpoint
  - JSON formatted output

### Demo Scenarios

Click any demo button to see:

1. **Flow Diagram**: Step-by-step visualization
2. **Real-time Status**: Each step updates as it executes
3. **Final Results**: Summary of all service calls

#### Flow Diagram Indicators

- 🟡 **PENDING**: Step is executing
- 🟢 **SUCCESS**: Step completed successfully
- 🔴 **ERROR**: Step failed

### Metrics Panel

View aggregate statistics:
- **Total Requests**: All API calls made
- **Successful**: Requests returning 200 OK
- **Failed**: Requests with errors
- **Avg Response Time**: Mean response time in milliseconds

## Architecture

### Communication Flow

```
Browser (Dashboard)
    ↓
Load Balancer (ALB/Nginx)
    ↓
Path-based Routing
    ├─→ /api/users/* → Users Service
    ├─→ /api/posts/* → Posts Service
    └─→ /api/threads/* → Threads Service
```

### Service Endpoints

#### Users Service
- `GET /health` - Health check
- `GET /api/users` - List all users
- `GET /api/users/:id` - Get specific user

#### Posts Service
- `GET /health` - Health check
- `GET /api/posts/by-user/:userId` - Posts by user
- `GET /api/posts/in-thread/:threadId` - Posts in thread

#### Threads Service
- `GET /health` - Health check
- `GET /api/threads` - List all threads
- `GET /api/threads/:id` - Get specific thread

## Customization

### Adding New Demos

To add a custom demonstration scenario:

```javascript
async function customDemo(container) {
    addFlowStep(container, 1, 'Your first step...', 'pending');
    
    try {
        // Make API call
        const response = await fetch(`${baseUrl}/api/your-endpoint`);
        const data = await response.json();
        
        // Update step status
        updateFlowStep(container, 1, `Completed: ${data.message}`, 'success');
        
        // Add more steps as needed
        addFlowStep(container, 2, 'Next step...', 'success');
    } catch (error) {
        addFlowStep(container, 'ERROR', `Failed: ${error.message}`, 'error');
    }
}
```

Then add a button:
```html
<button class="demo-btn" onclick="runDemo('customDemo')">Your Demo</button>
```

### Styling Customization

Key CSS classes for customization:
- `.service-card` - Individual service cards
- `.demo-btn` - Demo scenario buttons
- `.flow-step` - Communication flow steps
- `.metric-card` - Metrics display cards

### Configuration Options

Modify these JavaScript variables:
```javascript
let baseUrl = 'http://localhost:8080';  // Default URL
let checkInterval = 30000;  // Health check interval (ms)
```

## Troubleshooting

### Services Show as Offline

1. **Verify Services Are Running**:
```powershell
docker-compose ps
# or
aws ecs list-tasks --cluster your-cluster-name
```

2. **Check Load Balancer**:
```powershell
curl http://your-alb-url/api/users/health
```

3. **Review CORS Settings**:
- Ensure services allow cross-origin requests
- Check browser console for CORS errors

### Tests Return Errors

1. **Check Endpoint Paths**:
- Verify ALB listener rules are configured
- Test endpoints directly with curl

2. **Review Service Logs**:
```powershell
# Docker
docker-compose logs -f users

# AWS ECS
aws logs tail /ecs/forum-microservices-dev --follow
```

3. **Network Issues**:
- Check security groups allow inbound traffic
- Verify target group health checks

### Demo Scenarios Fail

1. **Check Data Availability**:
- Ensure db.json files have data
- Verify IDs match across services

2. **Review Service Dependencies**:
- Some demos require specific data
- Check that all services are healthy

3. **Browser Console**:
- Open DevTools (F12)
- Check console for JavaScript errors
- Review network tab for failed requests

## Best Practices

### For Demonstrations

1. **Start with Health Checks**:
   - Verify all services are healthy first
   - Run simple tests before complex demos

2. **Use Full Service Chain Sparingly**:
   - It makes many API calls
   - Can impact service performance
   - Best for showing complete workflow

3. **Monitor Metrics**:
   - Watch for increasing error rates
   - Track response time trends
   - Reset metrics between demos

### For Development

1. **Local Testing**:
   - Use Docker Compose for consistent environment
   - Test dashboard before AWS deployment

2. **AWS Testing**:
   - Use DR region for testing when possible
   - Avoid production during demos

3. **Data Management**:
   - Keep db.json files synchronized
   - Use consistent IDs across services

## Integration with CI/CD

### Automated Testing

The dashboard can be used for automated E2E testing:

```javascript
// Example Puppeteer test
const puppeteer = require('puppeteer');

async function testDashboard() {
    const browser = await puppeteer.launch();
    const page = await browser.newPage();
    
    await page.goto('http://localhost:8080/dashboard.html');
    
    // Wait for health checks
    await page.waitForSelector('.status-healthy');
    
    // Click demo button
    await page.click('button:contains("Get User with Posts")');
    
    // Verify success
    const successSteps = await page.$$('.step-status.success');
    expect(successSteps.length).toBeGreaterThan(0);
    
    await browser.close();
}
```

### Performance Monitoring

Track dashboard metrics over time:
- Response times
- Error rates
- Service availability

## Advanced Features

### Custom Endpoints

Add organization-specific endpoints:

```javascript
// In dashboard.html
const customEndpoints = {
    users: [
        { path: '/api/users/search', method: 'GET' },
        { path: '/api/users/active', method: 'GET' }
    ]
};
```

### Real-Time Updates

Add WebSocket support for live updates:

```javascript
const ws = new WebSocket('ws://your-alb-url/ws');

ws.onmessage = function(event) {
    const data = JSON.parse(event.data);
    updateServiceStatus(data.service, data.status);
};
```

### Export Metrics

Add CSV export functionality:

```javascript
function exportMetrics() {
    const csv = `Metric,Value\n` +
                `Total Requests,${metrics.total}\n` +
                `Successful,${metrics.successful}\n` +
                `Failed,${metrics.failed}\n` +
                `Avg Response Time,${avgResponseTime}ms`;
    
    // Download CSV
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'metrics.csv';
    a.click();
}
```

## Resources

- [Microservices Patterns](https://microservices.io/patterns/index.html)
- [Service Mesh Concepts](https://www.redhat.com/en/topics/microservices/what-is-a-service-mesh)
- [API Gateway Patterns](https://docs.aws.amazon.com/apigateway/latest/developerguide/welcome.html)
