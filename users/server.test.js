const request = require('supertest');
const Koa = require('koa');
const Router = require('@koa/router');
const cors = require('@koa/cors');

// Mock db.json
jest.mock('./db.json', () => ({
  users: [
    { id: 1, name: 'Alice Johnson', email: 'alice@example.com' },
    { id: 2, name: 'Bob Smith', email: 'bob@example.com' },
    { id: 3, name: 'Charlie Brown', email: 'charlie@example.com' }
  ]
}), { virtual: true });

// Import after mocking
const db = require('./db.json');

// Create test app
function createApp() {
  const app = new Koa();
  const router = new Router();
  const SERVICE_NAME = 'users-service';

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

  router.get('/api/users', async (ctx) => {
    ctx.body = db.users;
  });

  router.get('/api/users/:userId', async (ctx) => {
    const id = parseInt(ctx.params.userId);
    ctx.body = db.users.find((user) => user.id === id);
  });

  router.get('/api/', async (ctx) => {
    ctx.body = {
      message: 'Users API ready to receive requests',
      service: SERVICE_NAME,
      version: '1.0.0'
    };
  });

  router.get('/', async (ctx) => {
    ctx.body = {
      message: 'Users service is running',
      service: SERVICE_NAME
    };
  });

  app.use(router.routes());
  app.use(router.allowedMethods());

  return app.callback();
}

describe('Users Service API', () => {
  let app;

  beforeEach(() => {
    app = createApp();
  });

  describe('GET /health', () => {
    it('should return healthy status', async () => {
      const response = await request(app).get('/health');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('status', 'healthy');
      expect(response.body).toHaveProperty('service', 'users-service');
      expect(response.body).toHaveProperty('timestamp');
    });
  });

  describe('GET /', () => {
    it('should return service running message', async () => {
      const response = await request(app).get('/');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message', 'Users service is running');
      expect(response.body).toHaveProperty('service', 'users-service');
    });
  });

  describe('GET /api/', () => {
    it('should return API ready message', async () => {
      const response = await request(app).get('/api/');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message', 'Users API ready to receive requests');
      expect(response.body).toHaveProperty('version', '1.0.0');
    });
  });

  describe('GET /api/users', () => {
    it('should return all users', async () => {
      const response = await request(app).get('/api/users');
      
      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body).toHaveLength(3);
      expect(response.body[0]).toHaveProperty('name', 'Alice Johnson');
    });
  });

  describe('GET /api/users/:userId', () => {
    it('should return a specific user', async () => {
      const response = await request(app).get('/api/users/1');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('id', 1);
      expect(response.body).toHaveProperty('name', 'Alice Johnson');
      expect(response.body).toHaveProperty('email', 'alice@example.com');
    });

    it('should return undefined for non-existent user', async () => {
      const response = await request(app).get('/api/users/999');
      
      expect(response.status).toBe(200);
      expect(response.body).toBeUndefined();
    });
  });

  describe('CORS', () => {
    it('should include CORS headers', async () => {
      const response = await request(app).get('/api/users');
      
      expect(response.headers).toHaveProperty('access-control-allow-origin');
    });
  });

  describe('Error Handling', () => {
    it('should handle 404 for unknown routes', async () => {
      const response = await request(app).get('/api/unknown');
      
      expect(response.status).toBe(404);
    });
  });
});
