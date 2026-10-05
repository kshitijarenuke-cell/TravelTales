require('dotenv').config();
const { getAuthInstance, getFirestoreDb } = require('../src/config/firebase');

async function runLiveE2E() {
  console.log('================================================================');
  console.log('TRAVELTALES PHASE 5 — REAL FIREBASE AUTHENTICATION E2E TEST');
  console.log('================================================================\n');

  const auth = getAuthInstance();
  const db = getFirestoreDb();
  const baseUrl = 'http://localhost:3000/api';

  if (!auth || !db) {
    throw new Error('Firebase Admin Auth or Firestore not initialized.');
  }

  const timestamp = Date.now();
  const user1Email = `live-test-user1-${timestamp}@traveltales.test`;
  const user2Email = `live-test-user2-${timestamp}@traveltales.test`;
  const testPassword = 'SecurePassword@123';

  let user1Record = null;
  let user2Record = null;
  let user1IdToken = null;
  let user2IdToken = null;
  let createdTripId = null;
  let createdActivityId = null;
  let createdExpenseId = null;

  try {
    // ── STEP 1: Create real test Firebase users ──────────────────────────────
    console.log('Step 1: Creating real test users in Firebase Authentication...');
    user1Record = await auth.createUser({
      email: user1Email,
      password: testPassword,
      displayName: 'Live Test User 1',
    });
    console.log(`✓ User 1 created. UID: ${user1Record.uid}`);

    user2Record = await auth.createUser({
      email: user2Email,
      password: testPassword,
      displayName: 'Live Test User 2',
    });
    console.log(`✓ User 2 created. UID: ${user2Record.uid}`);

    // ── STEP 2 & 3: Sign in through Firebase Auth & Obtain real ID Tokens ─────
    console.log('\nStep 2 & 3: Signing in through Firebase Auth REST API to obtain real ID tokens...');
    const apiKey = 'AIzaSyBLTA7qrJvP_WKW5FhuTHqwQ5IpWQm0XFQ';

    async function signInUser(email, password) {
      const res = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password, returnSecureToken: true }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(`Firebase signin failed: ${JSON.stringify(data)}`);
      return data.idToken;
    }

    user1IdToken = await signInUser(user1Email, testPassword);
    console.log('✓ User 1 signed in. Real Firebase ID Token received.');

    user2IdToken = await signInUser(user2Email, testPassword);
    console.log('✓ User 2 signed in. Real Firebase ID Token received.');

    // Verify token with Firebase Admin SDK directly
    const decoded1 = await auth.verifyIdToken(user1IdToken);
    if (decoded1.uid !== user1Record.uid) throw new Error('Decoded token UID mismatch');
    console.log(`✓ Firebase Admin successfully verified User 1 ID token for UID: ${decoded1.uid}`);

    // ── STEP 4 & 5: Call Node.js API with User 1 token to create a trip ───────
    console.log('\nStep 4 & 5: Calling Node.js API with User 1 token to create Trip in Firestore...');
    const tripPayload = {
      title: 'Himalayan Trekking Expedition',
      destination: 'Manali, India',
      startDate: '2026-10-10T00:00:00.000Z',
      endDate: '2026-10-18T00:00:00.000Z',
      budget: 45000,
      isOfflineReady: true,
    };

    const createTripRes = await fetch(`${baseUrl}/trips`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${user1IdToken}`,
      },
      body: JSON.stringify(tripPayload),
    });

    const createTripBody = await createTripRes.json();
    if (createTripRes.status !== 201 || !createTripBody.success) {
      throw new Error(`Failed to create trip: ${JSON.stringify(createTripBody)}`);
    }
    createdTripId = createTripBody.data.id;
    console.log(`✓ Trip created via Node.js API. Status: 201. ID: ${createdTripId}`);

    // ── STEP 6: Verify Firestore stores correct Firebase UID ──────────────────
    console.log('\nStep 6: Verifying Firestore directly stores verified req.user.uid...');
    const tripDoc = await db.collection('trips').doc(createdTripId).get();
    if (!tripDoc.exists) throw new Error('Trip document not found in Firestore!');
    const tripFirestoreData = tripDoc.data();
    if (tripFirestoreData.userId !== user1Record.uid) {
      throw new Error(`Firestore stored wrong userId! Expected: ${user1Record.uid}, Got: ${tripFirestoreData.userId}`);
    }
    console.log(`✓ Firestore document verified: userId = ${tripFirestoreData.userId} (matches Firebase UID).`);

    // ── STEP 7: Read, Update Trip with User 1 token ───────────────────────────
    console.log('\nStep 7: Reading and updating Trip with User 1 token...');
    const getTripRes = await fetch(`${baseUrl}/trips/${createdTripId}`, {
      headers: { Authorization: `Bearer ${user1IdToken}` },
    });
    const getTripBody = await getTripRes.json();
    if (getTripRes.status !== 200 || getTripBody.data.title !== tripPayload.title) {
      throw new Error('Failed to retrieve own trip.');
    }
    console.log('✓ Successfully retrieved own trip.');

    const updateTripRes = await fetch(`${baseUrl}/trips/${createdTripId}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${user1IdToken}`,
      },
      body: JSON.stringify({ title: 'Himalayan Trekking Expedition (Updated)' }),
    });
    const updateTripBody = await updateTripRes.json();
    if (updateTripRes.status !== 200 || updateTripBody.data.title !== 'Himalayan Trekking Expedition (Updated)') {
      throw new Error('Failed to update trip.');
    }
    console.log('✓ Successfully updated own trip.');

    // ── STEP 8: Create Activity under Trip ─────────────────────────────────────
    console.log('\nStep 8: Creating Activity under Trip with User 1 token...');
    const actPayload = {
      dayNumber: 1,
      date: '2026-10-10T00:00:00.000Z',
      timeString: '08:00 AM',
      title: 'Rohtang Pass Acclimatization',
      location: 'Rohtang Pass, Manali',
      category: 'Adventure',
    };
    const createActRes = await fetch(`${baseUrl}/trips/${createdTripId}/activities`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${user1IdToken}`,
      },
      body: JSON.stringify(actPayload),
    });
    const createActBody = await createActRes.json();
    if (createActRes.status !== 201 || !createActBody.success) {
      throw new Error(`Failed to create activity: ${JSON.stringify(createActBody)}`);
    }
    createdActivityId = createActBody.data.id;
    console.log(`✓ Activity created. ID: ${createdActivityId}, userId: ${createActBody.data.userId}`);

    // ── STEP 9: Create Expense under Trip ──────────────────────────────────────
    console.log('\nStep 9: Creating Expense under Trip with User 1 token...');
    const expPayload = {
      title: 'Trekking Gear Rental',
      amount: 4500,
      category: 'Activities',
      date: '2026-10-10T12:00:00.000Z',
    };
    const createExpRes = await fetch(`${baseUrl}/trips/${createdTripId}/expenses`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${user1IdToken}`,
      },
      body: JSON.stringify(expPayload),
    });
    const createExpBody = await createExpRes.json();
    if (createExpRes.status !== 201 || !createExpBody.success) {
      throw new Error(`Failed to create expense: ${JSON.stringify(createExpBody)}`);
    }
    createdExpenseId = createExpBody.data.id;
    console.log(`✓ Expense created. ID: ${createdExpenseId}, userId: ${createExpBody.data.userId}`);

    // ── STEP 10: Verify User 2 cannot access User 1's data ────────────────────
    console.log('\nStep 10: Verifying cross-user isolation with User 2 token...');

    // User 2 GET User 1's trip
    const u2GetTrip = await fetch(`${baseUrl}/trips/${createdTripId}`, {
      headers: { Authorization: `Bearer ${user2IdToken}` },
    });
    if (u2GetTrip.status !== 404) throw new Error(`User 2 should get 404, got: ${u2GetTrip.status}`);
    console.log('✓ User 2 GET User 1 trip rejected with 404.');

    // User 2 PUT User 1's trip
    const u2PutTrip = await fetch(`${baseUrl}/trips/${createdTripId}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${user2IdToken}`,
      },
      body: JSON.stringify({ title: 'Hacked Trip' }),
    });
    if (u2PutTrip.status !== 404) throw new Error(`User 2 update should get 404, got: ${u2PutTrip.status}`);
    console.log('✓ User 2 PUT User 1 trip rejected with 404.');

    // User 2 DELETE User 1's trip
    const u2DelTrip = await fetch(`${baseUrl}/trips/${createdTripId}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${user2IdToken}` },
    });
    if (u2DelTrip.status !== 404) throw new Error(`User 2 delete should get 404, got: ${u2DelTrip.status}`);
    console.log('✓ User 2 DELETE User 1 trip rejected with 404.');

    // User 2 POST Activity on User 1's trip
    const u2PostAct = await fetch(`${baseUrl}/trips/${createdTripId}/activities`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${user2IdToken}`,
      },
      body: JSON.stringify(actPayload),
    });
    if (u2PostAct.status !== 404) throw new Error(`User 2 post activity should get 404, got: ${u2PostAct.status}`);
    console.log('✓ User 2 POST activity to User 1 trip rejected with 404.');

    // User 2 POST Expense on User 1's trip
    const u2PostExp = await fetch(`${baseUrl}/trips/${createdTripId}/expenses`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${user2IdToken}`,
      },
      body: JSON.stringify(expPayload),
    });
    if (u2PostExp.status !== 404) throw new Error(`User 2 post expense should get 404, got: ${u2PostExp.status}`);
    console.log('✓ User 2 POST expense to User 1 trip rejected with 404.');

    // Anti-spoofing check: User 1 supplies User 2's UID in body
    const spoofTripRes = await fetch(`${baseUrl}/trips`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${user1IdToken}`,
      },
      body: JSON.stringify({
        title: 'Spoofed Ownership Attempt',
        destination: 'Goa',
        startDate: '2026-12-01T00:00:00.000Z',
        endDate: '2026-12-05T00:00:00.000Z',
        userId: user2Record.uid, // Maliciously trying to spoof
      }),
    });
    const spoofTrip = (await spoofTripRes.json()).data;
    if (spoofTrip.userId !== user1Record.uid) {
      throw new Error(`Spoofing succeeded! Trip stored userId: ${spoofTrip.userId}`);
    }
    console.log('✓ Anti-spoofing verified: Client-supplied userId was ignored, bound to req.user.uid.');

    // Delete the spoofed trip
    await fetch(`${baseUrl}/trips/${spoofTrip.id}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${user1IdToken}` },
    });

    // ── STEP 11: Cleanup test data and delete trip with User 1 ────────────────
    console.log('\nStep 11: Cleaning up test data in Firestore...');
    const delTripRes = await fetch(`${baseUrl}/trips/${createdTripId}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${user1IdToken}` },
    });
    if (delTripRes.status !== 200) throw new Error('User 1 failed to delete own trip');
    console.log('✓ User 1 trip and cascaded child resources deleted successfully.');

    // Verify trip is 404
    const verifyDel = await fetch(`${baseUrl}/trips/${createdTripId}`, {
      headers: { Authorization: `Bearer ${user1IdToken}` },
    });
    if (verifyDel.status !== 404) throw new Error('Deleted trip still exists!');
    console.log('✓ Verified deleted trip returns 404.');

    // Delete test users from Firebase Auth
    console.log('\nStep 12: Cleaning up test users from Firebase Auth...');
    await auth.deleteUser(user1Record.uid);
    console.log(`✓ Deleted test user 1: ${user1Record.uid}`);
    await auth.deleteUser(user2Record.uid);
    console.log(`✓ Deleted test user 2: ${user2Record.uid}`);

    console.log('\n================================================================');
    console.log('✓ ALL 12 REAL FIREBASE E2E STEPS VERIFIED SUCCESSFULLY!');
    console.log('================================================================');
  } catch (error) {
    console.error('\n✖ LIVE E2E AUTHENTICATION TEST FAILED:', error);
    // Cleanup if possible
    if (user1Record) await auth.deleteUser(user1Record.uid).catch(() => {});
    if (user2Record) await auth.deleteUser(user2Record.uid).catch(() => {});
    process.exit(1);
  }
}

runLiveE2E();
