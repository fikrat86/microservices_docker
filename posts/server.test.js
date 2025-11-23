const request = require('supertest');
const Koa = require('koa');
const Router = require('@koa/router');
const cors = require('@koa/cors');

// Mock db.json
jest.mock('./db.json', () => ({
  posts: [
    { id: 1, thread: 1, user: 1, content: 'First post!', created: '2024-01-15T10:00:00Z' },
    { id: 2, thread: 1, user: 2, content: 'Great discussion!', created: '2024-01-15T11:00:00Z' },
    { id: 3, thread: 2, user: 1, content: 'Another post', created: '2024-01-16T09:00:00Z' }
  ]
}), { virtual: true });

const db = require('./db.json');

function createApp() {
  const app = new Koa();
  const router = new Router();
  const SERVICE_NAME = 'posts-service';

  app.use(cors());

  app.use(async (ctx, next) => {
    try {
      await next();
    } catch (err) {
      ctx.status = err.status || 500;
      ctx.body = {
        error: err.message,
        service: SERVICE_NAME
      };
    }
  });

  router.get('/health', async (ctx) => {
    ctx.body = {
      status: 'healthy',
      service: SERVICE_NAME,
      timestamp: new Date().toISOString()
    };
  });

  router.get('/api/posts/in-thread/:threadId', async (ctx) => {
    const id = parseInt(ctx.params.threadId);
    ctx.body = db.posts.filter((post) => post.thread === id);
  });

  router.get('/api/posts/by-user/:userId', async (ctx) => {
    const id = parseInt(ctx.params.userId);
    ctx.body = db.posts.filter((post) => post.user === id);
  });

  router.get('/api/', async (ctx) => {
    ctx.body = {
      message: 'Posts API ready to receive requests',
      service: SERVICE_NAME,
      version: '1.0.0'
    };
  });

  router.get('/', async (ctx) => {
    ctx.body = {
      message: 'Posts service is running',
      service: SERVICE_NAME
    };
  });

  app.use(router.routes());
  app.use(router.allowedMethods());

  return app.callback();
}

describe('Posts Service API', () => {
  let app;

  beforeEach(() => {
    app = createApp();
  });

  describe('GET /health', () => {
    it('should return healthy status', async () => {
      const response = await request(app).get('/health');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('status', 'healthy');
      expect(response.body).toHaveProperty('service', 'posts-service');
    });
  });

  describe('GET /', () => {
    it('should return service running message', async () => {
      const response = await request(app).get('/');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message', 'Posts service is running');
    });
  });

  describe('GET /api/', () => {
    it('should return API ready message', async () => {
      const response = await request(app).get('/api/');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message', 'Posts API ready to receive requests');
    });
  });

  describe('GET /api/posts/in-thread/:threadId', () => {
    it('should return posts in a specific thread', async () => {
      const response = await request(app).get('/api/posts/in-thread/1');
      
      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body).toHaveLength(2);
      expect(response.body[0]).toHaveProperty('thread', 1);
    });

    it('should return empty array for thread with no posts', async () => {
      const response = await request(app).get('/api/posts/in-thread/999');
      
      expect(response.status).toBe(200);
      expect(response.body).toEqual([]);
    });
  });

  describe('GET /api/posts/by-user/:userId', () => {
    it('should return posts by a specific user', async () => {
      const response = await request(app).get('/api/posts/by-user/1');
      
      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body).toHaveLength(2);
      expect(response.body[0]).toHaveProperty('user', 1);
    });

    it('should return empty array for user with no posts', async () => {
      const response = await request(app).get('/api/posts/by-user/999');
      
      expect(response.status).toBe(200);
      expect(response.body).toEqual([]);
    });
  });

  describe('CORS', () => {
    it('should include CORS headers', async () => {
      const response = await request(app).get('/api/posts/by-user/1');
      
      expect(response.headers).toHaveProperty('access-control-allow-origin');
    });
  });
});
