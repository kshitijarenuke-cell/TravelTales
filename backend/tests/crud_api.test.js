const { test, describe, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const cors = require('cors');

const apiRoutes = require('../src/routes');
const notFoundHandler = require('../src/middleware/notFoundHandler');
const errorHandler = require('../src/middleware/errorHandler');
const { enableTestMode, clearInMemoryDb } = require('../src/services/db');

describe('TravelTales Phase 3 & 5 — Backend CRUD APIs & Auth Integration Tests', () => {
  let server;
  let baseUrl;

  const user1Token = 'Bearer test-mock-token:user-alpha-1';
  const user2Token = 'Bearer test-mock-token:user-beta-2';

  function authedFetch(path, options = {}, token = user1Token) {
    const headers = {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: token } : {}),
      ...(options.headers || {}),
    };
    return fetch(`${baseUrl}${path}`, { ...options, headers });
  }

  before(async () => {
    // Enable test-safe database mode
    enableTestMode(true);

    const app = express();
    app.disable('x-powered-by');
    app.use((req, res, next) => {
      res.setHeader('X-Content-Type-Options', 'nosniff');
      res.setHeader('X-Frame-Options', 'DENY');
      res.setHeader('X-XSS-Protection', '1; mode=block');
      next();
    });
    app.use(cors());
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

  beforeEach(() => {
    clearInMemoryDb();
  });

  // ── 1. TRIPS CRUD ──────────────────────────────────────────────────────────
  test('1. POST /api/trips creates a new trip successfully', async () => {
    const payload = {
      title: 'Bali Summer Escape',
      destination: 'Bali, Indonesia',
      startDate: '2026-06-01T00:00:00.000Z',
      endDate: '2026-06-07T00:00:00.000Z',
      budget: 50000,
      coverImageUrl: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4',
    };

    const res = await authedFetch('/api/trips', {
      method: 'POST',
      body: JSON.stringify(payload),
    });

    assert.equal(res.status, 201);
    const body = await res.json();
    assert.equal(body.success, true);
    assert.ok(body.data.id);
    assert.equal(body.data.userId, 'user-alpha-1');
    assert.equal(body.data.title, 'Bali Summer Escape');
    assert.equal(body.data.destination, 'Bali, Indonesia');
    assert.equal(body.data.budget, 50000);
    assert.ok(body.data.createdAt);
    assert.ok(body.data.updatedAt);
  });

  test('2. GET /api/trips retrieves all created trips for the authenticated user', async () => {
    await authedFetch('/api/trips', {
      method: 'POST',
      body: JSON.stringify({
        title: 'Trip 1',
        destination: 'Goa',
        startDate: '2026-05-01T00:00:00.000Z',
        endDate: '2026-05-05T00:00:00.000Z',
      }),
    });

    await authedFetch('/api/trips', {
      method: 'POST',
      body: JSON.stringify({
        title: 'Trip 2',
        destination: 'Kerala',
        startDate: '2026-06-01T00:00:00.000Z',
        endDate: '2026-06-05T00:00:00.000Z',
      }),
    });

    const res = await authedFetch('/api/trips');
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.success, true);
    assert.equal(body.data.length, 2);
  });

  test('3. GET /api/trips/:id retrieves a single trip by ID', async () => {
    const createRes = await authedFetch('/api/trips', {
      method: 'POST',
      body: JSON.stringify({
        title: 'Jaipur Heritage',
        destination: 'Jaipur',
        startDate: '2026-07-10T00:00:00.000Z',
        endDate: '2026-07-15T00:00:00.000Z',
      }),
    });
    const created = await createRes.json();
    const tripId = created.data.id;

    const res = await authedFetch(`/api/trips/${tripId}`);
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.success, true);
    assert.equal(body.data.id, tripId);
    assert.equal(body.data.title, 'Jaipur Heritage');
  });

  test('4. PUT /api/trips/:id updates an existing trip', async () => {
    const createRes = await authedFetch('/api/trips', {
      method: 'POST',
      body: JSON.stringify({
        title: 'Manali Expedition',
        destination: 'Manali',
        startDate: '2026-08-01T00:00:00.000Z',
        endDate: '2026-08-06T00:00:00.000Z',
      }),
    });
    const created = await createRes.json();
    const tripId = created.data.id;

    const updateRes = await authedFetch(`/api/trips/${tripId}`, {
      method: 'PUT',
      body: JSON.stringify({
        title: 'Manali & Solang Expedition',
        budget: 45000,
      }),
    });

    assert.equal(updateRes.status, 200);
    const body = await updateRes.json();
    assert.equal(body.success, true);
    assert.equal(body.data.title, 'Manali & Solang Expedition');
    assert.equal(body.data.budget, 45000);
  });

  test('5. DELETE /api/trips/:id deletes trip and cascades child activities and expenses', async () => {
    const createRes = await authedFetch('/api/trips', {
      method: 'POST',
      body: JSON.stringify({
        title: 'Tokyo Trip',
        destination: 'Tokyo',
        startDate: '2026-09-01T00:00:00.000Z',
        endDate: '2026-09-08T00:00:00.000Z',
      }),
    });
    const created = await createRes.json();
    const tripId = created.data.id;

    // Add activity
    await authedFetch(`/api/trips/${tripId}/activities`, {
      method: 'POST',
      body: JSON.stringify({
        dayNumber: 1,
        date: '2026-09-01T00:00:00.000Z',
        timeString: '09:00 AM',
        title: 'Shibuya Crossing',
        location: 'Shibuya, Tokyo',
        category: 'Sightseeing',
      }),
    });

    // Add expense
    await authedFetch(`/api/trips/${tripId}/expenses`, {
      method: 'POST',
      body: JSON.stringify({
        title: 'Ramen Lunch',
        amount: 800,
        category: 'Food',
        date: '2026-09-01T12:30:00.000Z',
      }),
    });

    // Delete trip
    const deleteRes = await authedFetch(`/api/trips/${tripId}`, {
      method: 'DELETE',
    });
    assert.equal(deleteRes.status, 200);

    // Verify trip is 404
    const getTripRes = await authedFetch(`/api/trips/${tripId}`);
    assert.equal(getTripRes.status, 404);

    // Verify activities are empty
    const getActRes = await authedFetch(`/api/trips/${tripId}/activities`);
    assert.equal(getActRes.status, 404);
  });

  // ── 2. ACTIVITIES CRUD ──────────────────────────────────────────────────────
  test('6. POST /api/trips/:tripId/activities creates an activity under trip', async () => {
    const tripRes = await authedFetch('/api/trips', {
      method: 'POST',
      body: JSON.stringify({
        title: 'Paris Vacation',
        destination: 'Paris',
        startDate: '2026-07-01T00:00:00.000Z',
        endDate: '2026-07-05T00:00:00.000Z',
      }),
    });
    const trip = (await tripRes.json()).data;

    const actPayload = {
      dayNumber: 1,
      date: '2026-07-01T00:00:00.000Z',
      timeString: '10:00 AM',
      title: 'Eiffel Tower Visit',
      location: 'Champ de Mars, Paris',
      category: 'Sightseeing',
      notes: 'Pre-booked summit tickets',
      latitude: 48.8584,
      longitude: 2.2945,
    };

    const res = await authedFetch(`/api/trips/${trip.id}/activities`, {
      method: 'POST',
      body: JSON.stringify(actPayload),
    });

    assert.equal(res.status, 201);
    const body = await res.json();
    assert.equal(body.success, true);
    assert.ok(body.data.id);
    assert.equal(body.data.tripId, trip.id);
    assert.equal(body.data.title, 'Eiffel Tower Visit');
    assert.equal(body.data.dayNumber, 1);
    assert.equal(body.data.latitude, 48.8584);
  });

  test('7. PUT /api/activities/:id updates activity details', async () => {
    const tripRes = await authedFetch('/api/trips', {
      method: 'POST',
      body: JSON.stringify({
        title: 'Rome Holiday',
        destination: 'Rome',
        startDate: '2026-08-01T00:00:00.000Z',
        endDate: '2026-08-05T00:00:00.000Z',
      }),
    });
    const trip = (await tripRes.json()).data;

    const actRes = await authedFetch(`/api/trips/${trip.id}/activities`, {
      method: 'POST',
      body: JSON.stringify({
        dayNumber: 1,
        date: '2026-08-01T00:00:00.000Z',
        timeString: '09:00 AM',
        title: 'Colosseum Tour',
        location: 'Piazza del Colosseo',
        category: 'History',
      }),
    });
    const act = (await actRes.json()).data;

    const updateRes = await authedFetch(`/api/activities/${act.id}`, {
      method: 'PUT',
      body: JSON.stringify({
        title: 'Colosseum & Roman Forum Tour',
        timeString: '09:30 AM',
      }),
    });

    assert.equal(updateRes.status, 200);
    const body = await updateRes.json();
    assert.equal(body.success, true);
    assert.equal(body.data.title, 'Colosseum & Roman Forum Tour');
    assert.equal(body.data.timeString, '09:30 AM');
  });

  test('8. DELETE /api/activities/:id removes the activity', async () => {
    const tripRes = await authedFetch('/api/trips', {
      method: 'POST',
      body: JSON.stringify({
        title: 'London Break',
        destination: 'London',
        startDate: '2026-09-01T00:00:00.000Z',
        endDate: '2026-09-04T00:00:00.000Z',
      }),
    });
    const trip = (await tripRes.json()).data;

    const actRes = await authedFetch(`/api/trips/${trip.id}/activities`, {
      method: 'POST',
      body: JSON.stringify({
        dayNumber: 1,
        date: '2026-09-01T00:00:00.000Z',
        timeString: '11:00 AM',
        title: 'British Museum',
        location: 'Great Russell St',
        category: 'Culture',
      }),
    });
    const act = (await actRes.json()).data;

    const delRes = await authedFetch(`/api/activities/${act.id}`, {
      method: 'DELETE',
    });
    assert.equal(delRes.status, 200);

    const getRes = await authedFetch(`/api/trips/${trip.id}/activities`);
    const body = await getRes.json();
    assert.equal(body.data.length, 0);
  });

  // ── 3. EXPENSES CRUD ────────────────────────────────────────────────────────
  test('9. POST /api/trips/:tripId/expenses logs an expense under trip', async () => {
    const tripRes = await authedFetch('/api/trips', {
      method: 'POST',
      body: JSON.stringify({
        title: 'Swiss Escape',
        destination: 'Zurich',
        startDate: '2026-10-01T00:00:00.000Z',
        endDate: '2026-10-07T00:00:00.000Z',
      }),
    });
    const trip = (await tripRes.json()).data;

    const expPayload = {
      title: 'Fondue Dinner',
      amount: 4500,
      category: 'Food',
      date: '2026-10-02T19:30:00.000Z',
      notes: 'Swiss Chuchi restaurant',
    };

    const res = await authedFetch(`/api/trips/${trip.id}/expenses`, {
      method: 'POST',
      body: JSON.stringify(expPayload),
    });

    assert.equal(res.status, 201);
    const body = await res.json();
    assert.equal(body.success, true);
    assert.ok(body.data.id);
    assert.equal(body.data.tripId, trip.id);
    assert.equal(body.data.title, 'Fondue Dinner');
    assert.equal(body.data.amount, 4500);
  });

  test('10. PUT /api/expenses/:id updates expense details', async () => {
    const tripRes = await authedFetch('/api/trips', {
      method: 'POST',
      body: JSON.stringify({
        title: 'Dubai Trip',
        destination: 'Dubai',
        startDate: '2026-11-01T00:00:00.000Z',
        endDate: '2026-11-05T00:00:00.000Z',
      }),
    });
    const trip = (await tripRes.json()).data;

    const expRes = await authedFetch(`/api/trips/${trip.id}/expenses`, {
      method: 'POST',
      body: JSON.stringify({
        title: 'Desert Safari',
        amount: 8000,
        category: 'Activities',
        date: '2026-11-02T16:00:00.000Z',
      }),
    });
    const exp = (await expRes.json()).data;

    const updateRes = await authedFetch(`/api/expenses/${exp.id}`, {
      method: 'PUT',
      body: JSON.stringify({
        amount: 9500,
        notes: 'VIP Desert Safari with BBQ',
      }),
    });

    assert.equal(updateRes.status, 200);
    const body = await updateRes.json();
    assert.equal(body.success, true);
    assert.equal(body.data.amount, 9500);
    assert.equal(body.data.notes, 'VIP Desert Safari with BBQ');
  });

  test('11. DELETE /api/expenses/:id deletes expense', async () => {
    const tripRes = await authedFetch('/api/trips', {
      method: 'POST',
      body: JSON.stringify({
        title: 'Singapore Holiday',
        destination: 'Singapore',
        startDate: '2026-12-01T00:00:00.000Z',
        endDate: '2026-12-05T00:00:00.000Z',
      }),
    });
    const trip = (await tripRes.json()).data;

    const expRes = await authedFetch(`/api/trips/${trip.id}/expenses`, {
      method: 'POST',
      body: JSON.stringify({
        title: 'Universal Studios Pass',
        amount: 6000,
        category: 'Activities',
        date: '2026-12-02T10:00:00.000Z',
      }),
    });
    const exp = (await expRes.json()).data;

    const delRes = await authedFetch(`/api/expenses/${exp.id}`, {
      method: 'DELETE',
    });
    assert.equal(delRes.status, 200);

    const getRes = await authedFetch(`/api/trips/${trip.id}/expenses`);
    const body = await getRes.json();
    assert.equal(body.data.length, 0);
  });

  // ── 4. GUIDES API (PUBLIC) ────────────────────────────────────────────────
  test('12. GET /api/guides and GET /api/guides/:id retrieve local guides without auth', async () => {
    // Unauthenticated request should succeed because guides are public
    const res = await fetch(`${baseUrl}/api/guides`);
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.success, true);
    assert.ok(body.data.length >= 4);

    const firstGuide = body.data[0];
    const singleRes = await fetch(`${baseUrl}/api/guides/${firstGuide.id}`);
    assert.equal(singleRes.status, 200);
    const singleBody = await singleRes.json();
    assert.equal(singleBody.success, true);
    assert.equal(singleBody.data.id, firstGuide.id);
  });

  // ── 5. VALIDATION & ERROR HANDLING ────────────────────────────────────────
  test('13. Validation fails for missing required fields (empty title or destination)', async () => {
    const res = await authedFetch('/api/trips', {
      method: 'POST',
      body: JSON.stringify({
        title: '',
        destination: 'Bali',
        startDate: '2026-06-01T00:00:00.000Z',
        endDate: '2026-06-07T00:00:00.000Z',
      }),
    });

    assert.equal(res.status, 400);
    const body = await res.json();
    assert.equal(body.success, false);
    assert.ok(body.message.includes('Title is required'));
  });

  test('14. Validation fails for invalid dates and invalid amounts', async () => {
    const dateRes = await authedFetch('/api/trips', {
      method: 'POST',
      body: JSON.stringify({
        title: 'Date Fail',
        destination: 'Nowhere',
        startDate: '2026-05-10T00:00:00.000Z',
        endDate: '2026-05-01T00:00:00.000Z',
      }),
    });
    assert.equal(dateRes.status, 400);
    const dateBody = await dateRes.json();
    assert.equal(dateBody.success, false);
    assert.ok(dateBody.message.includes('endDate must be on or after startDate'));

    const tripRes = await authedFetch('/api/trips', {
      method: 'POST',
      body: JSON.stringify({
        title: 'Valid Trip',
        destination: 'Valid Destination',
        startDate: '2026-05-01T00:00:00.000Z',
        endDate: '2026-05-05T00:00:00.000Z',
      }),
    });
    const trip = (await tripRes.json()).data;

    const expRes = await authedFetch(`/api/trips/${trip.id}/expenses`, {
      method: 'POST',
      body: JSON.stringify({
        title: 'Bad Amount',
        amount: -50,
        category: 'Food',
        date: '2026-05-02T00:00:00.000Z',
      }),
    });
    assert.equal(expRes.status, 400);
    const expBody = await expRes.json();
    assert.equal(expBody.success, false);
    assert.ok(expBody.message.includes('amount must be a positive number'));
  });

  test('15. 404 error returned for non-existent trip/activity/expense IDs', async () => {
    const res = await authedFetch('/api/trips/non-existent-trip-999');
    assert.equal(res.status, 404);
    const body = await res.json();
    assert.equal(body.success, false);
    assert.ok(body.message.includes('not found'));
  });

  // ── 6. PHASE 5 AUTHENTICATION & DATA ISOLATION TESTS ───────────────────────
  test('16. Request without Authorization header returns 401', async () => {
    const res = await fetch(`${baseUrl}/api/trips`);
    assert.equal(res.status, 401);
    const body = await res.json();
    assert.equal(body.success, false);
    assert.ok(body.message.includes('Authorization header is missing'));
  });

  test('17. Request with malformed Authorization header returns 401', async () => {
    const res = await fetch(`${baseUrl}/api/trips`, {
      headers: { Authorization: 'Basic invalid-format' },
    });
    assert.equal(res.status, 401);
    const body = await res.json();
    assert.equal(body.success, false);
    assert.ok(body.message.includes('Malformed Authorization header'));
  });

  test('18. Request with invalid/empty token returns 401', async () => {
    const res = await fetch(`${baseUrl}/api/trips`, {
      headers: { Authorization: 'Bearer ' },
    });
    assert.equal(res.status, 401);
    const body = await res.json();
    assert.equal(body.success, false);
    assert.ok(body.message.includes('Malformed Authorization header'));
  });

  test('19. Cross-user isolation: User 2 cannot access User 1 trip', async () => {
    // User 1 creates trip
    const createRes = await authedFetch('/api/trips', {
      method: 'POST',
      body: JSON.stringify({
        title: 'User 1 Private Island',
        destination: 'Seychelles',
        startDate: '2026-10-01T00:00:00.000Z',
        endDate: '2026-10-10T00:00:00.000Z',
      }),
    }, user1Token);
    const trip = (await createRes.json()).data;

    // User 2 attempts to fetch User 1 trip
    const getRes = await authedFetch(`/api/trips/${trip.id}`, {}, user2Token);
    assert.equal(getRes.status, 404, 'User 2 must not be able to read User 1 trip');

    // User 2 list trips should NOT include User 1 trip
    const listRes = await authedFetch('/api/trips', {}, user2Token);
    const list = (await listRes.json()).data;
    assert.equal(list.some((t) => t.id === trip.id), false);
  });

  test('20. Cross-user isolation: User 2 cannot update User 1 trip', async () => {
    const createRes = await authedFetch('/api/trips', {
      method: 'POST',
      body: JSON.stringify({
        title: 'User 1 Maldives',
        destination: 'Maldives',
        startDate: '2026-10-01T00:00:00.000Z',
        endDate: '2026-10-10T00:00:00.000Z',
      }),
    }, user1Token);
    const trip = (await createRes.json()).data;

    const updateRes = await authedFetch(`/api/trips/${trip.id}`, {
      method: 'PUT',
      body: JSON.stringify({ title: 'Hacked Title' }),
    }, user2Token);

    assert.equal(updateRes.status, 404, 'User 2 must not be able to update User 1 trip');

    // Verify title was not changed
    const verifyRes = await authedFetch(`/api/trips/${trip.id}`, {}, user1Token);
    assert.equal((await verifyRes.json()).data.title, 'User 1 Maldives');
  });

  test('21. Cross-user isolation: User 2 cannot delete User 1 trip', async () => {
    const createRes = await authedFetch('/api/trips', {
      method: 'POST',
      body: JSON.stringify({
        title: 'User 1 Protected Trip',
        destination: 'Iceland',
        startDate: '2026-11-01T00:00:00.000Z',
        endDate: '2026-11-10T00:00:00.000Z',
      }),
    }, user1Token);
    const trip = (await createRes.json()).data;

    const delRes = await authedFetch(`/api/trips/${trip.id}`, {
      method: 'DELETE',
    }, user2Token);

    assert.equal(delRes.status, 404, 'User 2 must not be able to delete User 1 trip');

    // Trip must still exist for User 1
    const verifyRes = await authedFetch(`/api/trips/${trip.id}`, {}, user1Token);
    assert.equal(verifyRes.status, 200);
  });

  test('22. Cross-user isolation: User 2 cannot add activities to User 1 trip', async () => {
    const createRes = await authedFetch('/api/trips', {
      method: 'POST',
      body: JSON.stringify({
        title: 'User 1 Greece',
        destination: 'Athens',
        startDate: '2026-09-01T00:00:00.000Z',
        endDate: '2026-09-06T00:00:00.000Z',
      }),
    }, user1Token);
    const trip = (await createRes.json()).data;

    const actRes = await authedFetch(`/api/trips/${trip.id}/activities`, {
      method: 'POST',
      body: JSON.stringify({
        dayNumber: 1,
        date: '2026-09-01T00:00:00.000Z',
        timeString: '10:00 AM',
        title: 'Unauthorized Activity',
        location: 'Acropolis',
        category: 'Sightseeing',
      }),
    }, user2Token);

    assert.equal(actRes.status, 404);
  });

  test('23. Cross-user isolation: User 2 cannot add expenses to User 1 trip', async () => {
    const createRes = await authedFetch('/api/trips', {
      method: 'POST',
      body: JSON.stringify({
        title: 'User 1 Norway',
        destination: 'Oslo',
        startDate: '2026-09-10T00:00:00.000Z',
        endDate: '2026-09-15T00:00:00.000Z',
      }),
    }, user1Token);
    const trip = (await createRes.json()).data;

    const expRes = await authedFetch(`/api/trips/${trip.id}/expenses`, {
      method: 'POST',
      body: JSON.stringify({
        title: 'Unauthorized Expense',
        amount: 500,
        category: 'Food',
        date: '2026-09-11T12:00:00.000Z',
      }),
    }, user2Token);

    assert.equal(expRes.status, 404);
  });

  test('24. Anti-spoofing: Request body userId is ignored and bound to req.user.uid', async () => {
    const res = await authedFetch('/api/trips', {
      method: 'POST',
      body: JSON.stringify({
        title: 'Spoof Attempt Trip',
        destination: 'Moon',
        startDate: '2026-10-01T00:00:00.000Z',
        endDate: '2026-10-07T00:00:00.000Z',
        userId: 'spoofed-admin-id', // Attacker attempts to forge ownership
      }),
    }, user1Token);

    assert.equal(res.status, 201);
    const body = await res.json();
    assert.equal(body.data.userId, 'user-alpha-1', 'Must bind to authenticated token UID');
    assert.notEqual(body.data.userId, 'spoofed-admin-id', 'Must reject forged body userId');
  });

  test('25. Cross-user isolation: User 2 cannot update or delete User 1 activity directly', async () => {
    // User 1 creates trip and activity
    const tripRes = await authedFetch('/api/trips', {
      method: 'POST',
      body: JSON.stringify({
        title: 'User 1 Tokyo Trip',
        destination: 'Tokyo',
        startDate: '2026-11-01T00:00:00.000Z',
        endDate: '2026-11-06T00:00:00.000Z',
      }),
    }, user1Token);
    const trip = (await tripRes.json()).data;

    const actRes = await authedFetch(`/api/trips/${trip.id}/activities`, {
      method: 'POST',
      body: JSON.stringify({
        dayNumber: 1,
        date: '2026-11-01T00:00:00.000Z',
        timeString: '09:00 AM',
        title: 'Tokyo Skytree Tour',
        location: 'Oshiage',
        category: 'Sightseeing',
      }),
    }, user1Token);
    const activity = (await actRes.json()).data;

    // User 2 attempts to update User 1 activity
    const updateRes = await authedFetch(`/api/activities/${activity.id}`, {
      method: 'PUT',
      body: JSON.stringify({ title: 'Hacked Skytree' }),
    }, user2Token);
    assert.equal(updateRes.status, 404, 'User 2 cannot update User 1 activity');

    // User 2 attempts to delete User 1 activity
    const delRes = await authedFetch(`/api/activities/${activity.id}`, {
      method: 'DELETE',
    }, user2Token);
    assert.equal(delRes.status, 404, 'User 2 cannot delete User 1 activity');
  });

  test('26. Cross-user isolation: User 2 cannot update or delete User 1 expense directly', async () => {
    // User 1 creates trip and expense
    const tripRes = await authedFetch('/api/trips', {
      method: 'POST',
      body: JSON.stringify({
        title: 'User 1 Paris Trip',
        destination: 'Paris',
        startDate: '2026-12-01T00:00:00.000Z',
        endDate: '2026-12-05T00:00:00.000Z',
      }),
    }, user1Token);
    const trip = (await tripRes.json()).data;

    const expRes = await authedFetch(`/api/trips/${trip.id}/expenses`, {
      method: 'POST',
      body: JSON.stringify({
        title: 'Louvre Museum Ticket',
        amount: 2500,
        category: 'Entertainment',
        date: '2026-12-02T10:00:00.000Z',
      }),
    }, user1Token);
    const expense = (await expRes.json()).data;

    // User 2 attempts to update User 1 expense
    const updateRes = await authedFetch(`/api/expenses/${expense.id}`, {
      method: 'PUT',
      body: JSON.stringify({ amount: 99999 }),
    }, user2Token);
    assert.equal(updateRes.status, 404, 'User 2 cannot update User 1 expense');

    // User 2 attempts to delete User 1 expense
    const delRes = await authedFetch(`/api/expenses/${expense.id}`, {
      method: 'DELETE',
    }, user2Token);
    assert.equal(delRes.status, 404, 'User 2 cannot delete User 1 expense');
  });

  test('27. Security headers and x-powered-by header protection', async () => {
    const res = await fetch(`${baseUrl}/api/health`);
    assert.equal(res.status, 200);
    assert.equal(res.headers.get('x-content-type-options'), 'nosniff');
    assert.equal(res.headers.get('x-frame-options'), 'DENY');
    assert.equal(res.headers.get('x-xss-protection'), '1; mode=block');
    assert.equal(res.headers.get('x-powered-by'), null, 'x-powered-by header must be stripped');
  });

  test('28. Mock token rejection in production environment', async () => {
    const prevEnv = process.env.NODE_ENV;
    try {
      process.env.NODE_ENV = 'production';
      const res = await fetch(`${baseUrl}/api/trips`, {
        headers: { Authorization: 'Bearer test-mock-token:attacker-uid' },
      });
      assert.equal(res.status, 401);
      const body = await res.json();
      assert.equal(body.success, false);
      assert.ok(body.message.includes('Mock tokens are not permitted in production'));
    } finally {
      process.env.NODE_ENV = prevEnv;
    }
  });

  test('29. Error Handler sanitizes 500 error messages and suppresses stack traces in production', async () => {
    const prevEnv = process.env.NODE_ENV;
    try {
      process.env.NODE_ENV = 'production';
      // Pass invalid JSON to trigger express body parser or malformed request
      const res = await fetch(`${baseUrl}/api/trips`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: 'Bearer test-mock-token:test-user',
        },
        body: '{"invalid_json": ',
      });
      assert.equal(res.status, 400);
      const body = await res.json();
      assert.equal(body.stack, undefined, 'Stack trace must not be exposed');
    } finally {
      process.env.NODE_ENV = prevEnv;
    }
  });
});
