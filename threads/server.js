require('dotenv').config();
const Koa = require('koa');
const Router = require('@koa/router');
const cors = require('@koa/cors');
const bodyParser = require('koa-bodyparser');
const { v4: uuidv4 } = require('uuid');
const db = require('./db.json');

const app = new Koa();
const router = new Router({
  prefix: '/api/threads'
});

const PORT = process.env.PORT || 3000;
const SERVICE_NAME = 'threads-service';

// CORS middleware
app.use(cors());

// Body parser middleware
app.use(bodyParser());

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
router.get('/', async (ctx) => {
  ctx.body = db.threads;
});

router.post('/', async (ctx) => {
  const { userId, title, category } = ctx.request.body;
  const newThread = {
    threadId: uuidv4(),
    userId,
    title,
    category: category || 'general',
    createdAt: new Date().toISOString()
  };
  db.threads.push(newThread);
  ctx.status = 201;
  ctx.body = newThread;
});

router.get('/:threadId', async (ctx) => {
  const thread = db.threads.find((t) => t.threadId === ctx.params.threadId);
  if (!thread) {
    ctx.status = 404;
    ctx.body = { error: 'Thread not found' };
    return;
  }
  ctx.body = thread;
});

app.use(router.routes());
app.use(router.allowedMethods());

app.listen(PORT, () => {
  console.log(`${SERVICE_NAME} started on port ${PORT}`);
});
