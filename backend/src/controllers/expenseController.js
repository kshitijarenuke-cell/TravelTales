const expenseService = require('../services/expenseService');

const expenseController = {
  async createExpense(req, res, next) {
    try {
      const userId = req.user.uid;
      const tripId = req.params.tripId || req.body.tripId;

      const expense = await expenseService.createExpense(userId, tripId, req.body);
      if (!expense) {
        return res.status(404).json({
          success: false,
          message: `Cannot add expense: Trip not found or unauthorized with ID ${tripId}`,
        });
      }

      return res.status(201).json({
        success: true,
        data: expense,
      });
    } catch (error) {
      next(error);
    }
  },

  async getExpensesForTrip(req, res, next) {
    try {
      const userId = req.user.uid;
      const { tripId } = req.params;

      const expenses = await expenseService.getExpensesByTripId(userId, tripId);
      if (!expenses) {
        return res.status(404).json({
          success: false,
          message: `Trip not found or unauthorized with ID ${tripId}`,
        });
      }

      return res.status(200).json({
        success: true,
        data: expenses,
      });
    } catch (error) {
      next(error);
    }
  },

  async updateExpense(req, res, next) {
    try {
      const userId = req.user.uid;
      const { id } = req.params;
      const expense = await expenseService.updateExpense(userId, id, req.body);

      if (!expense) {
        return res.status(404).json({
          success: false,
          message: `Expense not found or unauthorized with ID ${id}`,
        });
      }

      return res.status(200).json({
        success: true,
        data: expense,
      });
    } catch (error) {
      next(error);
    }
  },

  async deleteExpense(req, res, next) {
    try {
      const userId = req.user.uid;
      const { id } = req.params;
      const result = await expenseService.deleteExpense(userId, id);

      if (!result) {
        return res.status(404).json({
          success: false,
          message: `Expense not found or unauthorized with ID ${id}`,
        });
      }

      return res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  },
};

module.exports = expenseController;
