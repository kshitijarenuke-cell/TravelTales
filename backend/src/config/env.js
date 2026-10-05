const dotenv = require('dotenv');

// Load environment variables from .env
dotenv.config();

function parseAllowedOrigins(value) {
  if (!value) return [];
  return value
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
}

const config = {
  port: parseInt(process.env.PORT, 10) || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  allowedOrigins: parseAllowedOrigins(process.env.ALLOWED_ORIGINS),
  getAllowedOrigins: () => parseAllowedOrigins(process.env.ALLOWED_ORIGINS),
};

module.exports = config;

