const express = require('express');
const cors = require('cors');
const config = require('./src/config/env');
const { createCorsOptions } = require('./src/config/cors');
const apiRoutes = require('./src/routes');
const notFoundHandler = require('./src/middleware/notFoundHandler');
const errorHandler = require('./src/middleware/errorHandler');

const app = express();

// Disable x-powered-by banner
app.disable('x-powered-by');

// Standard security headers
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  next();
});

// Production-ready Cross-Origin Resource Sharing configuration
app.use(cors(createCorsOptions()));

// Body parsing middleware with size limits
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));

// Request logging middleware (logs method & path without exposing request bodies, tokens, or headers)
app.use((req, res, next) => {
  console.log(`[API] ${req.method} ${req.path}`);
  next();
});

// Root informational endpoint
app.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Welcome to TravelTales API',
  });
});

// API Routes
app.use('/api', apiRoutes);

// 404 handler for undefined routes
app.use(notFoundHandler);

// Central error handling middleware
app.use(errorHandler);

// Start listening (uses host process.env.PORT with safe fallback)
const PORT = parseInt(process.env.PORT, 10) || config.port || 3000;
const server = app.listen(PORT, () => {
  console.log(`TravelTales API server running on port ${PORT} [${process.env.NODE_ENV || config.nodeEnv}]`);
  console.log(`Health check endpoint: http://localhost:${PORT}/api/health`);
});

// Graceful shutdown handling for container recycling (SIGTERM/SIGINT)
const handleShutdown = (signal) => {
  console.log(`[API] Received ${signal}. Closing HTTP server gracefully...`);
  server.close((err) => {
    if (err) {
      console.error('[API] Error during server shutdown:', err.message);
      process.exit(1);
    }
    console.log('[API] HTTP server closed cleanly.');
    process.exit(0);
  });

  // Force close after 10 seconds if hanging connections exist
  const forceTimer = setTimeout(() => {
    console.error('[API] Forced shutdown after timeout.');
    process.exit(1);
  }, 10000);
  if (forceTimer.unref) forceTimer.unref();
};

process.on('SIGTERM', () => handleShutdown('SIGTERM'));
process.on('SIGINT', () => handleShutdown('SIGINT'));

module.exports = { app, server };
