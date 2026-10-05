const { getAuthInstance } = require('../config/firebase');

/**
 * Authentication middleware that verifies Firebase ID tokens using Firebase Admin SDK.
 * Attaches verified user information (uid, email) to req.user.
 * Rejects missing, malformed, invalid, or expired tokens with HTTP 401.
 */
async function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return res.status(401).json({
      success: false,
      message: 'Authorization header is missing. Expected Bearer token.',
    });
  }

  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer' || !parts[1].trim()) {
    return res.status(401).json({
      success: false,
      message: 'Malformed Authorization header. Format must be: Bearer <token>',
    });
  }

  const token = parts[1].trim();

  // Test mode mock token support strictly for non-production automated testing
  if (token.startsWith('test-mock-token:')) {
    if (process.env.NODE_ENV === 'production') {
      return res.status(401).json({
        success: false,
        message: 'Mock tokens are not permitted in production environment.',
      });
    }
    const uid = token.split(':')[1];
    req.user = {
      uid: uid || 'test-mock-user',
      email: `${uid}@example.com`,
    };
    return next();
  }

  const auth = getAuthInstance();
  if (!auth) {
    return res.status(503).json({
      success: false,
      message: 'Firebase Authentication service is not initialized on the server.',
    });
  }

  try {
    const decodedToken = await auth.verifyIdToken(token);
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email || null,
    };
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired authentication token.',
    });
  }
}

module.exports = authenticate;
