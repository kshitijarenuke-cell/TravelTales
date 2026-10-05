const { test, describe, before, after } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const cors = require('cors');

const { createCorsOptions } = require('../src/config/cors');
const apiRoutes = require('../src/routes');
const notFoundHandler = require('../src/middleware/notFoundHandler');
const errorHandler = require('../src/middleware/errorHandler');

describe('TravelTales — Production Readiness & Deployment Security Tests', () => {
  let server;
  let baseUrl;

  before(async () => {
    const app = express();
    app.disable('x-powered-by');
    app.use((req, res, next) => {
      res.setHeader('X-Content-Type-Options', 'nosniff');
      res.setHeader('X-Frame-Options', 'DENY');
      res.setHeader('X-XSS-Protection', '1; mode=block');
      next();
    });

    // Apply the production CORS options
    app.use(cors(createCorsOptions()));
    app.use(express.json());
    app.use('/api', apiRoutes);
    app.use(notFoundHandler);
    app.use(errorHandler);

    await new Promise((resolve) => {
      server = app.listen(0, () => {
        const address = server.address();
        baseUrl = `http://127.0.0.1:${address.port}`;
        resolve();
      });
    });
  });

  after(async () => {
    if (server) {
      await new Promise((resolve) => server.close(resolve));
    }
  });

  test('1. Requests without Origin header (Flutter mobile apps, curl, probes) are always permitted', async () => {
    const res = await fetch(`${baseUrl}/api/health`);
    assert.equal(res.status, 200);
    const data = await res.json();
    assert.equal(data.success, true);
  });

  test('2. CORS allows any origin in development mode', async () => {
    const prevEnv = process.env.NODE_ENV;
    try {
      process.env.NODE_ENV = 'development';
      const res = await fetch(`${baseUrl}/api/health`, {
        headers: { Origin: 'http://localhost:8080' },
      });
      assert.equal(res.status, 200);
      assert.equal(res.headers.get('access-control-allow-origin'), 'http://localhost:8080');
    } finally {
      process.env.NODE_ENV = prevEnv;
    }
  });

  test('3. CORS in production permits configured ALLOWED_ORIGINS', async () => {
    const prevEnv = process.env.NODE_ENV;
    const prevOrigins = process.env.ALLOWED_ORIGINS;
    try {
      process.env.NODE_ENV = 'production';
      process.env.ALLOWED_ORIGINS = 'https://traveltales.vercel.app,https://my-domain.com';

      const res = await fetch(`${baseUrl}/api/health`, {
        headers: { Origin: 'https://traveltales.vercel.app' },
      });
      assert.equal(res.status, 200);
      assert.equal(res.headers.get('access-control-allow-origin'), 'https://traveltales.vercel.app');
    } finally {
      process.env.NODE_ENV = prevEnv;
      process.env.ALLOWED_ORIGINS = prevOrigins;
    }
  });

  test('4. CORS in production rejects unauthorized origins with 403 Forbidden', async () => {
    const prevEnv = process.env.NODE_ENV;
    const prevOrigins = process.env.ALLOWED_ORIGINS;
    try {
      process.env.NODE_ENV = 'production';
      process.env.ALLOWED_ORIGINS = 'https://traveltales.vercel.app';

      const res = await fetch(`${baseUrl}/api/health`, {
        headers: { Origin: 'https://malicious-website.com' },
      });
      assert.equal(res.status, 403);
      const data = await res.json();
      assert.equal(data.success, false);
      assert.ok(data.message.includes('not permitted'));
    } finally {
      process.env.NODE_ENV = prevEnv;
      process.env.ALLOWED_ORIGINS = prevOrigins;
    }
  });

  test('5. CORS in production supports wildcard patterns in ALLOWED_ORIGINS', async () => {
    const prevEnv = process.env.NODE_ENV;
    const prevOrigins = process.env.ALLOWED_ORIGINS;
    try {
      process.env.NODE_ENV = 'production';
      process.env.ALLOWED_ORIGINS = 'https://*.vercel.app';

      const res = await fetch(`${baseUrl}/api/health`, {
        headers: { Origin: 'https://traveltales-staging.vercel.app' },
      });
      assert.equal(res.status, 200);
      assert.equal(res.headers.get('access-control-allow-origin'), 'https://traveltales-staging.vercel.app');
    } finally {
      process.env.NODE_ENV = prevEnv;
      process.env.ALLOWED_ORIGINS = prevOrigins;
    }
  });

  test('6. Health endpoint provides diagnostics (uptime, environment, timestamp) without leaking secrets', async () => {
    const res = await fetch(`${baseUrl}/api/health`);
    assert.equal(res.status, 200);
    const data = await res.json();
    assert.equal(data.success, true);
    assert.ok(typeof data.uptime === 'number');
    assert.ok(data.timestamp);
    assert.ok(data.environment);
    assert.ok(data.firebase);
    assert.ok(data.firestore);

    // Verify secrets are strictly absent
    const raw = JSON.stringify(data);
    assert.equal(raw.includes('privateKey'), false);
    assert.equal(raw.includes('private_key'), false);
    assert.equal(raw.includes('client_email'), false);
  });

  test('7. Security headers and x-powered-by protection', async () => {
    const res = await fetch(`${baseUrl}/api/health`);
    assert.equal(res.headers.get('x-content-type-options'), 'nosniff');
    assert.equal(res.headers.get('x-frame-options'), 'DENY');
    assert.equal(res.headers.get('x-xss-protection'), '1; mode=block');
    assert.equal(res.headers.get('x-powered-by'), null);
  });
});
