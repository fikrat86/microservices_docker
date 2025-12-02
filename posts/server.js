require('dotenv').config();
const Koa = require('koa');
const Router = require('@koa/router');
const cors = require('@koa/cors');
const bodyParser = require('koa-bodyparser');
const { v4: uuidv4 } = require('uuid');
const db = require('./db.json');

const app = new Koa();
const router = new Router();

const PORT = process.env.PORT || 3000;
const SERVICE_NAME = 'posts-service';

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

// Health check endpoint (for API calls through ALB)
router.get('/api/posts/health', async (ctx) => {
  ctx.body = {
    status: 'healthy',
    service: SERVICE_NAME,
    timestamp: new Date().toISOString()
  };
});

// API endpoints
router.get('/', async (ctx) => {
  ctx.body = db.posts;
});

// API endpoint (through ALB path-based routing)
router.get('/api/posts', async (ctx) => {
  ctx.body = db.posts;
});

// Direct route (without /api prefix)
router.get('/posts', async (ctx) => {
  ctx.body = db.posts;
});

router.post('/', async (ctx) => {
  const { userId, threadId, content } = ctx.request.body;
  const newPost = {
    postId: uuidv4(),
    userId,
    threadId,
    content,
    createdAt: new Date().toISOString()
  };
  db.posts.push(newPost);
  ctx.status = 201;
  ctx.body = newPost;
});

router.post('/api/posts', async (ctx) => {
  const { userId, threadId, content } = ctx.request.body;
  const newPost = {
    postId: uuidv4(),
    userId,
    threadId,
    content,
    createdAt: new Date().toISOString()
  };
  db.posts.push(newPost);
  ctx.status = 201;
  ctx.body = newPost;
});

router.post('/posts', async (ctx) => {
  const { userId, threadId, content } = ctx.request.body;
  const newPost = {
    postId: uuidv4(),
    userId,
    threadId,
    content,
    createdAt: new Date().toISOString()
  };
  db.posts.push(newPost);
  ctx.status = 201;
  ctx.body = newPost;
});

router.get('/:postId', async (ctx) => {
  const post = db.posts.find((p) => p.postId === ctx.params.postId);
  if (!post) {
    ctx.status = 404;
    ctx.body = { error: 'Post not found' };
    return;
  }
  ctx.body = post;
});

router.get('/api/posts/:postId', async (ctx) => {
  const post = db.posts.find((p) => p.postId === ctx.params.postId);
  if (!post) {
    ctx.status = 404;
    ctx.body = { error: 'Post not found' };
    return;
  }
  ctx.body = post;
});

router.get('/posts/:postId', async (ctx) => {
  const post = db.posts.find((p) => p.postId === ctx.params.postId);
  if (!post) {
    ctx.status = 404;
    ctx.body = { error: 'Post not found' };
    return;
  }
  ctx.body = post;
});

router.get('/in-thread/:threadId', async (ctx) => {
  const posts = db.posts.filter((p) => p.threadId === ctx.params.threadId);
  ctx.body = posts;
});

router.get('/by-user/:userId', async (ctx) => {
  const posts = db.posts.filter((p) => p.userId === ctx.params.userId);
  ctx.body = posts;
});

app.use(router.routes());
app.use(router.allowedMethods());

app.listen(PORT, () => {
  console.log(`${SERVICE_NAME} started on port ${PORT}`);
});
