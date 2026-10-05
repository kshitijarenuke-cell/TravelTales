/**
 * 404 Not Found Middleware
 * Handles requests to undefined routes and returns a structured JSON response.
 */
const notFoundHandler = (req, res, next) => {
  return res.status(404).json({
    success: false,
    message: `Route not found: ${req.method} ${req.originalUrl}`,
  });
};

module.exports = notFoundHandler;
