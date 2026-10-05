const { admin, getFirebaseStatus, getFirestoreDb } = require('../config/firebase');

/**
 * Checks and reports the current Firebase and Firestore connection status.
 * Never reports 'connected' unless Firebase Admin & Firestore have genuinely been initialized.
 *
 * @returns {Promise<{ connected: boolean, status: string, firestore: string, message: string }>}
 */
async function checkFirebaseConnection() {
  const initStatus = getFirebaseStatus();
  const firestoreDb = getFirestoreDb();

  // If credentials are not configured or encountered an error
  if (!initStatus.initialized || admin.getApps().length === 0 || !firestoreDb) {
    return {
      connected: false,
      status: initStatus.status || 'not_configured',
      firestore: initStatus.firestore || 'not_configured',
      message: initStatus.message || 'Firebase and Firestore are not configured.',
    };
  }

  // App and Firestore are genuinely initialized
  return {
    connected: true,
    status: 'connected',
    firestore: 'connected',
    message: initStatus.message || 'Firebase Admin SDK and Firestore are connected.',
  };
}

module.exports = {
  checkFirebaseConnection,
};
