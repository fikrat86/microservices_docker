require('dotenv').config();
const Koa = require('koa');
const Router = require('@koa/router');
const cors = require('@koa/cors');
const db = require('./db.json');

const app = new Koa();
const router = new Router();

const PORT = process.env.PORT || 3000;
const SERVICE_NAME = 'threads-service';

// CORS middleware
app.use(cors());

// Request logging middleware
app.use(async (ctx, next) => {
  const start = Date.now();
  await next();
  const ms = Date.now() - start;
  console.log(`${ctx.method} ${ctx.url} - ${ms}ms`);
});

// Error handling middleware
app.use(async (ctx, next) => {
  try {
    await next();
  } catch (err) {
    ctx.status = err.status || 500;
    ctx.body = {
      error: err.message,
      service: SERVICE_NAME
    };
    console.error('Error:', err);
  }
});

// Health check endpoint (for ALB health checks)
router.get('/health', async (ctx) => {
  ctx.body = {
    status: 'healthy',
    service: SERVICE_NAME,
    timestamp: new Date().toISOString()
  };
});

// API endpoints
router.get('/api/threads', async (ctx) => {
  ctx.body = db.threads;
});

router.get('/api/threads/:threadId', async (ctx) => {
  const id = parseInt(ctx.params.threadId);
  ctx.body = db.threads.find((thread) => thread.id == id);
});

router.get('/api/', async (ctx) => {
  ctx.body = {
    message: "Threads API ready to receive requests",
    service: SERVICE_NAME,
    version: '1.0.0'
  };
});

router.get('/', async (ctx) => {
  ctx.body = {
    message: "Threads service is running",
    service: SERVICE_NAME
  };
});

app.use(router.routes());
app.use(router.allowedMethods());

app.listen(PORT, () => {
  console.log(`${SERVICE_NAME} started on port ${PORT}`);
});
