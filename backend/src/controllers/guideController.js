const guideService = require('../services/guideService');

const guideController = {
  async getGuides(req, res, next) {
    try {
      const guides = await guideService.getGuides(req.query);
      return res.status(200).json({
        success: true,
        data: guides,
      });
    } catch (error) {
      next(error);
    }
  },

  async getGuideById(req, res, next) {
    try {
      const guide = await guideService.getGuideById(req.params.id);
      if (!guide) {
        return res.status(404).json({
          success: false,
          message: `Guide not found with ID ${req.params.id}`,
        });
      }
      return res.status(200).json({
        success: true,
        data: guide,
      });
    } catch (error) {
      next(error);
    }
  },
};

module.exports = guideController;
