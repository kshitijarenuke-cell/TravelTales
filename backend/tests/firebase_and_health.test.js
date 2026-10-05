const { test, describe, before, after } = require('node:test');
const assert = require('node:assert/strict');
const http = require('http');

const express = require('express');
const cors = require('cors');
const apiRoutes = require('../src/routes');
const notFoundHandler = require('../src/middleware/notFoundHandler');
const errorHandler = require('../src/middleware/errorHandler');
const { checkFirebaseConnection } = require('../src/services/firebaseService');
const { getFirebaseStatus } = require('../src/config/firebase');

describe('TravelTales Phase 2 - Backend & Firebase Verification', () => {
  let server;
  let baseUrl;

  before(async () => {
    const app = express();
    app.use(cors());
    app.use(express.json());
    app.use('/api', apiRoutes);
    app.use(notFoundHandler);
    app.use(errorHandler);

    // Listen on dynamic ephemeral port
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

  test('1. Firebase configuration does not crash the server when credentials are not configured', () => {
    const status = getFirebaseStatus();
    assert.equal(status.initialized, false, 'Firebase should not be initialized without credentials');
    assert.equal(status.status, 'not_configured', 'Status should be not_configured');
    assert.ok(status.message, 'Message should explain credentials are not configured');
  });

  test('2. checkFirebaseConnection() accurately returns not_configured and never fakes connected', async () => {
    const result = await checkFirebaseConnection();
    assert.equal(result.connected, false, 'connected must be false when not initialized');
    assert.equal(result.status, 'not_configured', 'status must be not_configured');
    assert.notEqual(result.status, 'connected', 'Must NEVER report connected without verified credentials');
  });

  test('3. GET /api/health returns 200 with valid structure and firebase status', async () => {
    const res = await fetch(`${baseUrl}/api/health`);
    assert.equal(res.status, 200, 'HTTP status should be 200');

    const data = await res.json();
    assert.equal(data.success, true, 'success field should be true');
    assert.equal(data.message, 'TravelTales API is running', 'message field should match requirement');
    assert.equal(data.firebase, 'not_configured', 'firebase field should reflect not_configured');
    assert.equal(data.firestore, 'not_configured', 'firestore field should reflect not_configured');
  });

  test('4. Existing 404 handler returns structured JSON response for undefined routes', async () => {
    const res = await fetch(`${baseUrl}/api/non-existent-route-endpoint`);
    assert.equal(res.status, 404, 'HTTP status should be 404');

    const data = await res.json();
    assert.equal(data.success, false, 'success field should be false');
    assert.ok(data.message.includes('Route not found'), 'message should describe route not found');
  });

  test('5. Verify security: no credentials or sensitive environment keys are leaked in responses', async () => {
    const healthRes = await fetch(`${baseUrl}/api/health`);
    const healthText = await healthRes.text();
    assert.equal(healthText.includes('privateKey'), false, 'Response must not contain privateKey');
    assert.equal(healthText.includes('private_key'), false, 'Response must not contain private_key');
    assert.equal(healthText.includes('client_email'), false, 'Response must not contain client_email');
  });

  test('6. Verify error resilience: non-existent service account path does not crash server and reports not_configured', async () => {
    process.env.FIREBASE_SERVICE_ACCOUNT_PATH = './non-existent-service-account.json';
    const { initializeFirebase } = require('../src/config/firebase');
    const app = initializeFirebase();
    assert.equal(app, null, 'Should return null for non-existent service account file');
    delete process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  });

  test('7. Verify Firebase Admin SDK & Firestore successfully initialize with valid service account path', async () => {
    process.env.FIREBASE_SERVICE_ACCOUNT_PATH = './firebase-service-account.json';
    const { initializeFirebase, getFirebaseStatus, getFirestoreDb } = require('../src/config/firebase');
    const { checkFirebaseConnection } = require('../src/services/firebaseService');

    const app = initializeFirebase();
    assert.ok(app, 'Firebase app should initialize with valid service account path');

    const status = getFirebaseStatus();
    assert.equal(status.initialized, true, 'Firebase should report initialized: true');
    assert.equal(status.status, 'connected', 'Status should be connected');
    assert.equal(status.firestore, 'connected', 'Firestore should be connected');

    const db = getFirestoreDb();
    assert.ok(db, 'Firestore instance should be available');

    const healthCheck = await checkFirebaseConnection();
    assert.equal(healthCheck.connected, true, 'Health check should report connected: true');
    assert.equal(healthCheck.status, 'connected');
    assert.equal(healthCheck.firestore, 'connected');

    delete process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  });
});
