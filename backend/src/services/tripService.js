const crypto = require('crypto');
const { getDb } = require('./db');

const COLLECTION_NAME = 'trips';

/**
 * Service managing Firestore CRUD operations for Trips scoped to authenticated users
 */
const tripService = {
  async createTrip(userId, data) {
    const db = getDb();
    const id = data.id || `trip-${crypto.randomUUID().slice(0, 8)}`;
    const now = new Date().toISOString();

    const newTrip = {
      id,
      userId, // Strictly derived from verified req.user.uid
      title: data.title.trim(),
      destination: data.destination.trim(),
      startDate: new Date(data.startDate).toISOString(),
      endDate: new Date(data.endDate).toISOString(),
      coverImageUrl: data.coverImageUrl || null,
      budget: data.budget !== undefined ? Number(data.budget) : 40000.0,
      isOfflineReady: Boolean(data.isOfflineReady),
      createdAt: now,
      updatedAt: now,
    };

    const docRef = db.collection(COLLECTION_NAME).doc(id);
    await docRef.set(newTrip);
    return newTrip;
  },

  async getTrips(userId) {
    const db = getDb();
    const snapshot = await db.collection(COLLECTION_NAME).where('userId', '==', userId).get();
    const trips = [];
    snapshot.forEach((doc) => {
      trips.push(doc.data());
    });

    // Sort by startDate descending (newest first)
    trips.sort((a, b) => new Date(b.startDate).getTime() - new Date(a.startDate).getTime());
    return trips;
  },

  async getTripById(userId, id) {
    const db = getDb();
    const docRef = db.collection(COLLECTION_NAME).doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return null;
    }

    const tripData = doc.data();
    // Data isolation check: ensure trip belongs to requesting user
    if (tripData.userId !== userId) {
      return null;
    }

    return tripData;
  },

  async updateTrip(userId, id, data) {
    const db = getDb();
    const docRef = db.collection(COLLECTION_NAME).doc(id);
    const existing = await docRef.get();

    if (!existing.exists) {
      return null;
    }

    const current = existing.data();
    // Data isolation check
    if (current.userId !== userId) {
      return null;
    }

    const now = new Date().toISOString();

    const updated = {
      ...current,
      ...(data.title !== undefined && { title: data.title.trim() }),
      ...(data.destination !== undefined && { destination: data.destination.trim() }),
      ...(data.startDate !== undefined && { startDate: new Date(data.startDate).toISOString() }),
      ...(data.endDate !== undefined && { endDate: new Date(data.endDate).toISOString() }),
      ...(data.coverImageUrl !== undefined && { coverImageUrl: data.coverImageUrl }),
      ...(data.budget !== undefined && { budget: Number(data.budget) }),
      ...(data.isOfflineReady !== undefined && { isOfflineReady: Boolean(data.isOfflineReady) }),
      userId, // Ensure userId cannot be overwritten
      updatedAt: now,
    };

    await docRef.set(updated, { merge: true });
    return updated;
  },

  async deleteTrip(userId, id) {
    const db = getDb();
    const docRef = db.collection(COLLECTION_NAME).doc(id);
    const existing = await docRef.get();

    if (!existing.exists) {
      return null;
    }

    const current = existing.data();
    // Data isolation check
    if (current.userId !== userId) {
      return null;
    }

    // Delete trip
    await docRef.delete();

    // Cascade delete activities
    try {
      const activitiesSnapshot = await db.collection('activities').where('tripId', '==', id).get();
      for (const actDoc of activitiesSnapshot.docs) {
        await db.collection('activities').doc(actDoc.id).delete();
      }
    } catch (_) {}

    // Cascade delete expenses
    try {
      const expensesSnapshot = await db.collection('expenses').where('tripId', '==', id).get();
      for (const expDoc of expensesSnapshot.docs) {
        await db.collection('expenses').doc(expDoc.id).delete();
      }
    } catch (_) {}

    return { id, deleted: true };
  },
};

module.exports = tripService;
