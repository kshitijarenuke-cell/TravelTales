/**
 * Health Controller
 * Provides status endpoint for TravelTales API service health checks.
 */

const { checkFirebaseConnection } = require('../services/firebaseService');
const config = require('../config/env');

const getHealthStatus = async (req, res, next) => {
  try {
    const firebaseInfo = await checkFirebaseConnection();

    return res.status(200).json({
      success: true,
      message: 'TravelTales API is running',
      environment: process.env.NODE_ENV || config.nodeEnv,
      uptime: Math.floor(process.uptime()),
      timestamp: new Date().toISOString(),
      firebase: firebaseInfo.status,
      firestore: firebaseInfo.firestore,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getHealthStatus,
};
