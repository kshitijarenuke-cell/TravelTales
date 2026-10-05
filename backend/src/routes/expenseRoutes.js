const express = require('express');
const expenseController = require('../controllers/expenseController');
const { validateUpdateExpense, validateId } = require('../middleware/validator');
const authenticate = require('../middleware/authMiddleware');

const router = express.Router();
router.use(authenticate);

// PUT /api/expenses/:id
router.put('/:id', validateId('id'), validateUpdateExpense, expenseController.updateExpense);

// DELETE /api/expenses/:id
router.delete('/:id', validateId('id'), expenseController.deleteExpense);

module.exports = router;
