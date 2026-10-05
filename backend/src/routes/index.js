const express = require('express');
const healthRoutes = require('./healthRoutes');
const tripRoutes = require('./tripRoutes');
const activityRoutes = require('./activityRoutes');
const expenseRoutes = require('./expenseRoutes');
const guideRoutes = require('./guideRoutes');

const router = express.Router();

// Mount API Sub-Routers
router.use('/health', healthRoutes);
router.use('/trips', tripRoutes);
router.use('/activities', activityRoutes);
router.use('/expenses', expenseRoutes);
router.use('/guides', guideRoutes);

module.exports = router;
