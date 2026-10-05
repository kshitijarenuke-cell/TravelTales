const express = require('express');
const guideController = require('../controllers/guideController');
const { validateId } = require('../middleware/validator');

const router = express.Router();

// GET /api/guides
router.get('/', guideController.getGuides);

// GET /api/guides/:id
router.get('/:id', validateId('id'), guideController.getGuideById);

module.exports = router;
