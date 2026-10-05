const express = require('express');
const activityController = require('../controllers/activityController');
const { validateUpdateActivity, validateId } = require('../middleware/validator');
const authenticate = require('../middleware/authMiddleware');

const router = express.Router();
router.use(authenticate);

// PUT /api/activities/:id
router.put('/:id', validateId('id'), validateUpdateActivity, activityController.updateActivity);

// DELETE /api/activities/:id
router.delete('/:id', validateId('id'), activityController.deleteActivity);

module.exports = router;
