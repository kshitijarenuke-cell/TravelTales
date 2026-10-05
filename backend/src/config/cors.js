const config = require('./env');

/**
 * Creates CORS configuration options based on the environment and ALLOWED_ORIGINS.
 *
 * Rules:
 * - Requests without Origin (mobile Flutter apps, curl, internal health probes) are always allowed.
 * - In non-production environments (development / test), all origins are permitted.
 * - In production, only origins configured in ALLOWED_ORIGINS (or matching wildcard patterns) are permitted.
 * - Unauthorized web origins in production are rejected with a 403 Forbidden error.
 */
function createCorsOptions() {
  return {
    origin: (origin, callback) => {
      // 1. Requests with no origin (e.g. mobile apps, curl, server-to-server)
      if (!origin) {
        return callback(null, true);
      }

      const isProduction = process.env.NODE_ENV === 'production' || config.nodeEnv === 'production';

      // 2. In non-production, permit all origins for local development ease
      if (!isProduction) {
        return callback(null, true);
      }

      // 3. In production, check against ALLOWED_ORIGINS
      const allowedOrigins = config.getAllowedOrigins ? config.getAllowedOrigins() : (config.allowedOrigins || []);

      if (allowedOrigins.length === 0) {
        const corsError = new Error('CORS policy: No ALLOWED_ORIGINS configured for production.');
        corsError.status = 403;
        return callback(corsError);
      }

      // Check exact match
      if (allowedOrigins.includes(origin)) {
        return callback(null, true);
      }

      // Check wildcard match (e.g. https://*.traveltales.com, https://*-app.vercel.app)
      const matchesWildcard = allowedOrigins.some((pattern) => {
        if (pattern.includes('*')) {
          const escaped = pattern.replace(/[.+?^${}()|[\]\\]/g, '\\$&').replace(/\*/g, '.*');
          return new RegExp(`^${escaped}$`).test(origin);
        }
        return false;
      });

      if (matchesWildcard) {
        return callback(null, true);
      }

      const corsError = new Error(`CORS policy: Origin '${origin}' is not permitted.`);
      corsError.status = 403;
      return callback(corsError);
    },
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
    maxAge: 86400,
  };
}

module.exports = {
  createCorsOptions,
};
