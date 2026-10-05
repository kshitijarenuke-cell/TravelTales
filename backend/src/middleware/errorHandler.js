/**
 * Global Error Handler Middleware
 * Catches unhandled errors in express request pipeline and returns structured JSON response.
 */
// eslint-disable-next-line no-unused-vars
const errorHandler = (err, req, res, next) => {
  const statusCode = err.statusCode || err.status || 500;
  const isProduction = process.env.NODE_ENV === 'production';
  const message = (isProduction && statusCode >= 500)
    ? 'Internal Server Error'
    : (err.message || 'Internal Server Error');

  return res.status(statusCode).json({
    success: false,
    message,
    ...(!isProduction && { stack: err.stack }),
  });
};

module.exports = errorHandler;
