const request = require('supertest');
const Koa = require('koa');
const Router = require('@koa/router');
const cors = require('@koa/cors');

// Mock db.json
jest.mock('./db.json', () => ({
  threads: [
    { id: 1, title: 'Welcome to the Forum', description: 'Introduce yourself here', created: '2024-01-15T09:00:00Z' },
    { id: 2, title: 'General Discussion', description: 'Talk about anything', created: '2024-01-16T08:00:00Z' },
    { id: 3, title: 'Tech Talk', description: 'Technology discussions', created: '2024-01-17T07:00:00Z' }
  ]
}), { virtual: true });

const db = require('./db.json');

function createApp() {
  const app = new Koa();
  const router = new Router();
  const SERVICE_NAME = 'threads-service';

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

  router.get('/api/threads', async (ctx) => {
    ctx.body = db.threads;
  });

  router.get('/api/threads/:threadId', async (ctx) => {
    const id = parseInt(ctx.params.threadId);
    ctx.body = db.threads.find((thread) => thread.id === id);
  });

  router.get('/api/', async (ctx) => {
    ctx.body = {
      message: 'Threads API ready to receive requests',
      service: SERVICE_NAME,
      version: '1.0.0'
    };
  });

  router.get('/', async (ctx) => {
    ctx.body = {
      message: 'Threads service is running',
      service: SERVICE_NAME
    };
  });

  app.use(router.routes());
  app.use(router.allowedMethods());

  return app.callback();
}

describe('Threads Service API', () => {
  let app;

  beforeEach(() => {
    app = createApp();
  });

  describe('GET /health', () => {
    it('should return healthy status', async () => {
      const response = await request(app).get('/health');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('status', 'healthy');
      expect(response.body).toHaveProperty('service', 'threads-service');
    });
  });

  describe('GET /', () => {
    it('should return service running message', async () => {
      const response = await request(app).get('/');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message', 'Threads service is running');
    });
  });

  describe('GET /api/', () => {
    it('should return API ready message', async () => {
      const response = await request(app).get('/api/');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message', 'Threads API ready to receive requests');
    });
  });

  describe('GET /api/threads', () => {
    it('should return all threads', async () => {
      const response = await request(app).get('/api/threads');
      
      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body).toHaveLength(3);
      expect(response.body[0]).toHaveProperty('title', 'Welcome to the Forum');
    });
  });

  describe('GET /api/threads/:threadId', () => {
    it('should return a specific thread', async () => {
      const response = await request(app).get('/api/threads/1');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('id', 1);
      expect(response.body).toHaveProperty('title', 'Welcome to the Forum');
      expect(response.body).toHaveProperty('description');
    });

    it('should return undefined for non-existent thread', async () => {
      const response = await request(app).get('/api/threads/999');
      
      expect(response.status).toBe(200);
      expect(response.body).toBeUndefined();
    });
  });

  describe('CORS', () => {
    it('should include CORS headers', async () => {
      const response = await request(app).get('/api/threads');
      
      expect(response.headers).toHaveProperty('access-control-allow-origin');
    });
  });
});
