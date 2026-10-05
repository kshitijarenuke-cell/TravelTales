const express = require('express');
const tripController = require('../controllers/tripController');
const activityController = require('../controllers/activityController');
const expenseController = require('../controllers/expenseController');
const {
  validateCreateTrip,
  validateUpdateTrip,
  validateCreateActivity,
  validateCreateExpense,
  validateId,
} = require('../middleware/validator');
const authenticate = require('../middleware/authMiddleware');

const router = express.Router();

// Require valid Firebase ID Token for all Trip and nested sub-resource routes
router.use(authenticate);

// ── Trip CRUD ────────────────────────────────────────────────────────────────
// POST /api/trips
router.post('/', validateCreateTrip, tripController.createTrip);

// GET /api/trips
router.get('/', tripController.getTrips);

// GET /api/trips/:id
router.get('/:id', validateId('id'), tripController.getTripById);

// PUT /api/trips/:id
router.put('/:id', validateId('id'), validateUpdateTrip, tripController.updateTrip);

// DELETE /api/trips/:id
router.delete('/:id', validateId('id'), tripController.deleteTrip);

// ── Nested Itinerary Activities under Trip ───────────────────────────────────
// POST /api/trips/:tripId/activities
router.post(
  '/:tripId/activities',
  validateId('tripId'),
  validateCreateActivity,
  activityController.createActivity
);

// GET /api/trips/:tripId/activities
router.get(
  '/:tripId/activities',
  validateId('tripId'),
  activityController.getActivitiesForTrip
);

// ── Nested Expenses under Trip ────────────────────────────────────────────────
// POST /api/trips/:tripId/expenses
router.post(
  '/:tripId/expenses',
  validateId('tripId'),
  validateCreateExpense,
  expenseController.createExpense
);

// GET /api/trips/:tripId/expenses
router.get(
  '/:tripId/expenses',
  validateId('tripId'),
  expenseController.getExpensesForTrip
);

module.exports = router;
