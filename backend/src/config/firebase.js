const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

let firebaseApp = null;
let firestoreDb = null;
let firebaseAuth = null;
let firebaseStatus = {
  initialized: false,
  status: 'not_configured',
  firestore: 'not_configured',
  message: 'Firebase credentials are not configured.',
};

/**
 * Resolves the service account path relative to cwd or backend directory.
 * Returns null if path is invalid or file doesn't exist.
 */
function resolveServiceAccountPath(serviceAccountPath) {
  if (!serviceAccountPath) return null;
  const candidates = [
    path.isAbsolute(serviceAccountPath) ? serviceAccountPath : path.resolve(process.cwd(), serviceAccountPath),
    path.resolve(__dirname, '../../', serviceAccountPath),
    path.resolve(__dirname, '../../', path.basename(serviceAccountPath)),
  ];
  return candidates.find((c) => fs.existsSync(c)) || null;
}

/**
 * Initializes Firebase Admin SDK and Firestore using environment variables or a service account key file.
 * Safely handles missing or invalid credentials without crashing the server.
 */
function initializeFirebase() {
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;

  // If a service account path was explicitly specified but the file does not exist
  if (serviceAccountPath && !resolveServiceAccountPath(serviceAccountPath)) {
    firestoreDb = null;
    firebaseStatus = {
      initialized: false,
      status: 'not_configured',
      firestore: 'not_configured',
      message: `Service account file not found at: ${serviceAccountPath}`,
    };
    console.warn(`[Firebase] Service account file not found at: ${serviceAccountPath}`);
    return null;
  }

  // If already initialized in this process and no override error, reuse existing app and firestore
  const apps = admin.getApps();
  if (apps.length > 0) {
    firebaseApp = admin.getApp();
    try {
      firestoreDb = getFirestore(firebaseApp);
      firebaseAuth = getAuth(firebaseApp);
    } catch (_) {
      firestoreDb = null;
      firebaseAuth = null;
    }
    firebaseStatus = {
      initialized: true,
      status: 'connected',
      firestore: firestoreDb ? 'connected' : 'error',
      message: 'Firebase Admin SDK and Firestore are connected.',
    };
    return firebaseApp;
  }

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  let privateKey = process.env.FIREBASE_PRIVATE_KEY;

  try {
    // 1. Check for inline JSON string or base64 encoded JSON in environment variable
    const inlineJson =
      process.env.FIREBASE_SERVICE_ACCOUNT ||
      process.env.FIREBASE_SERVICE_ACCOUNT_KEY ||
      process.env.FIREBASE_SERVICE_ACCOUNT_JSON;

    if (inlineJson) {
      let parsed = null;
      try {
        parsed = JSON.parse(inlineJson);
      } catch (_) {
        try {
          const decoded = Buffer.from(inlineJson, 'base64').toString('utf8');
          parsed = JSON.parse(decoded);
        } catch (_) {}
      }

      if (
        parsed &&
        (parsed.project_id || parsed.projectId) &&
        (parsed.client_email || parsed.clientEmail) &&
        (parsed.private_key || parsed.privateKey)
      ) {
        if (parsed.private_key) {
          parsed.private_key = parsed.private_key.replace(/\\n/g, '\n');
        }
        if (parsed.privateKey) {
          parsed.privateKey = parsed.privateKey.replace(/\\n/g, '\n');
        }

        firebaseApp = admin.initializeApp({
          credential: admin.cert(parsed),
        });
        firestoreDb = getFirestore(firebaseApp);
        firebaseAuth = getAuth(firebaseApp);

        firebaseStatus = {
          initialized: true,
          status: 'connected',
          firestore: 'connected',
          message: 'Firebase Admin SDK and Firestore initialized via inline service account secret.',
        };
        console.log('Firebase Admin SDK & Firestore initialized successfully via inline service account secret.');
        return firebaseApp;
      }
    }

    // 2. Check for individual environment variables
    if (projectId && clientEmail && privateKey) {
      // Normalize escaped newlines in private key string
      privateKey = privateKey.replace(/\\n/g, '\n');

      firebaseApp = admin.initializeApp({
        credential: admin.cert({
          projectId,
          clientEmail,
          privateKey,
        }),
      });
      firestoreDb = getFirestore(firebaseApp);
      firebaseAuth = getAuth(firebaseApp);

      firebaseStatus = {
        initialized: true,
        status: 'connected',
        firestore: 'connected',
        message: 'Firebase Admin SDK and Firestore initialized via environment variables.',
      };
      console.log('Firebase Admin SDK & Firestore initialized successfully via environment variables.');
      return firebaseApp;
    }

    // 3. Check for service account JSON file path
    if (serviceAccountPath) {
      const resolvedPath = resolveServiceAccountPath(serviceAccountPath);

      if (resolvedPath) {
        const serviceAccount = JSON.parse(fs.readFileSync(resolvedPath, 'utf8'));
        firebaseApp = admin.initializeApp({
          credential: admin.cert(serviceAccount),
        });
        firestoreDb = getFirestore(firebaseApp);
        firebaseAuth = getAuth(firebaseApp);

        firebaseStatus = {
          initialized: true,
          status: 'connected',
          firestore: 'connected',
          message: 'Firebase Admin SDK and Firestore initialized via service account file.',
        };
        console.log('Firebase Admin SDK & Firestore initialized successfully via service account file.');
        return firebaseApp;
      }
    }

    // 4. Check for GOOGLE_APPLICATION_CREDENTIALS default
    if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      firebaseApp = admin.initializeApp({
        credential: admin.applicationDefault(),
      });
      firestoreDb = getFirestore(firebaseApp);
      firebaseAuth = getAuth(firebaseApp);

      firebaseStatus = {
        initialized: true,
        status: 'connected',
        firestore: 'connected',
        message: 'Firebase Admin SDK and Firestore initialized via application default credentials.',
      };
      console.log('Firebase Admin SDK & Firestore initialized via application default credentials.');
      return firebaseApp;
    }

    // No credentials provided
    firestoreDb = null;
    firebaseAuth = null;
    firebaseStatus = {
      initialized: false,
      status: 'not_configured',
      firestore: 'not_configured',
      message: 'Firebase credentials are not configured in environment.',
    };
    return null;
  } catch (error) {
    firestoreDb = null;
    firebaseAuth = null;
    firebaseStatus = {
      initialized: false,
      status: 'error',
      firestore: 'error',
      message: error.message,
    };
    console.error('[Firebase] Initialization error:', error.message);
    return null;
  }
}

// Auto-initialize on module load
initializeFirebase();

module.exports = {
  admin,
  getFirebaseApp: () => firebaseApp,
  getFirestoreDb: () => firestoreDb,
  getAuthInstance: () => firebaseAuth,
  getFirebaseStatus: () => ({ ...firebaseStatus }),
  initializeFirebase,
};
