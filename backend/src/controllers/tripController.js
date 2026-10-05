const tripService = require('../services/tripService');

const tripController = {
  async createTrip(req, res, next) {
    try {
      const userId = req.user.uid;
      const trip = await tripService.createTrip(userId, req.body);
      return res.status(201).json({
        success: true,
        data: trip,
      });
    } catch (error) {
      next(error);
    }
  },

  async getTrips(req, res, next) {
    try {
      const userId = req.user.uid;
      const trips = await tripService.getTrips(userId);
      return res.status(200).json({
        success: true,
        data: trips,
      });
    } catch (error) {
      next(error);
    }
  },

  async getTripById(req, res, next) {
    try {
      const userId = req.user.uid;
      const trip = await tripService.getTripById(userId, req.params.id);
      if (!trip) {
        return res.status(404).json({
          success: false,
          message: `Trip not found with ID ${req.params.id}`,
        });
      }
      return res.status(200).json({
        success: true,
        data: trip,
      });
    } catch (error) {
      next(error);
    }
  },

  async updateTrip(req, res, next) {
    try {
      const userId = req.user.uid;
      const trip = await tripService.updateTrip(userId, req.params.id, req.body);
      if (!trip) {
        return res.status(404).json({
          success: false,
          message: `Trip not found with ID ${req.params.id}`,
        });
      }
      return res.status(200).json({
        success: true,
        data: trip,
      });
    } catch (error) {
      next(error);
    }
  },

  async deleteTrip(req, res, next) {
    try {
      const userId = req.user.uid;
      const result = await tripService.deleteTrip(userId, req.params.id);
      if (!result) {
        return res.status(404).json({
          success: false,
          message: `Trip not found with ID ${req.params.id}`,
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

module.exports = tripController;
