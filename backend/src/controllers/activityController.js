const activityService = require('../services/activityService');

const activityController = {
  async createActivity(req, res, next) {
    try {
      const userId = req.user.uid;
      const tripId = req.params.tripId || req.body.tripId;

      const activity = await activityService.createActivity(userId, tripId, req.body);
      if (!activity) {
        return res.status(404).json({
          success: false,
          message: `Cannot add activity: Trip not found or unauthorized with ID ${tripId}`,
        });
      }

      return res.status(201).json({
        success: true,
        data: activity,
      });
    } catch (error) {
      next(error);
    }
  },

  async getActivitiesForTrip(req, res, next) {
    try {
      const userId = req.user.uid;
      const { tripId } = req.params;

      const activities = await activityService.getActivitiesByTripId(userId, tripId);
      if (!activities) {
        return res.status(404).json({
          success: false,
          message: `Trip not found or unauthorized with ID ${tripId}`,
        });
      }

      return res.status(200).json({
        success: true,
        data: activities,
      });
    } catch (error) {
      next(error);
    }
  },

  async updateActivity(req, res, next) {
    try {
      const userId = req.user.uid;
      const { id } = req.params;
      const activity = await activityService.updateActivity(userId, id, req.body);

      if (!activity) {
        return res.status(404).json({
          success: false,
          message: `Activity not found or unauthorized with ID ${id}`,
        });
      }

      return res.status(200).json({
        success: true,
        data: activity,
      });
    } catch (error) {
      next(error);
    }
  },

  async deleteActivity(req, res, next) {
    try {
      const userId = req.user.uid;
      const { id } = req.params;
      const result = await activityService.deleteActivity(userId, id);

      if (!result) {
        return res.status(404).json({
          success: false,
          message: `Activity not found or unauthorized with ID ${id}`,
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

module.exports = activityController;
