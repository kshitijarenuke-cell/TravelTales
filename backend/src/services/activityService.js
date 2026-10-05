const crypto = require('crypto');
const { getDb } = require('./db');

const COLLECTION_NAME = 'activities';

/**
 * Service managing Firestore CRUD operations for Itinerary Activities
 * strictly scoped to the authenticated user's trips.
 */
const activityService = {
  async createActivity(userId, tripId, data) {
    const db = getDb();

    // Verify parent trip belongs to the authenticated user
    const tripDoc = await db.collection('trips').doc(tripId).get();
    if (!tripDoc.exists || tripDoc.data().userId !== userId) {
      return null;
    }

    const id = data.id || `act-${crypto.randomUUID().slice(0, 8)}`;
    const now = new Date().toISOString();

    const newActivity = {
      id,
      tripId,
      userId,
      dayNumber: Number(data.dayNumber),
      date: new Date(data.date).toISOString(),
      timeString: data.timeString.trim(),
      title: data.title.trim(),
      location: data.location.trim(),
      category: data.category.trim(),
      notes: data.notes || null,
      latitude: data.latitude !== undefined && data.latitude !== null ? Number(data.latitude) : null,
      longitude: data.longitude !== undefined && data.longitude !== null ? Number(data.longitude) : null,
      createdAt: now,
      updatedAt: now,
    };

    const docRef = db.collection(COLLECTION_NAME).doc(id);
    await docRef.set(newActivity);
    return newActivity;
  },

  async getActivitiesByTripId(userId, tripId) {
    const db = getDb();

    // Verify parent trip belongs to the authenticated user
    const tripDoc = await db.collection('trips').doc(tripId).get();
    if (!tripDoc.exists || tripDoc.data().userId !== userId) {
      return null;
    }

    const snapshot = await db.collection(COLLECTION_NAME).where('tripId', '==', tripId).get();
    const activities = [];
    snapshot.forEach((doc) => {
      activities.push(doc.data());
    });

    // Sort by dayNumber asc, then timeString asc
    activities.sort((a, b) => {
      if (a.dayNumber !== b.dayNumber) {
        return a.dayNumber - b.dayNumber;
      }
      return a.timeString.localeCompare(b.timeString);
    });

    return activities;
  },

  async getActivityById(userId, id) {
    const db = getDb();
    const docRef = db.collection(COLLECTION_NAME).doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return null;
    }

    const activity = doc.data();
    // Verify parent trip belongs to user
    const tripDoc = await db.collection('trips').doc(activity.tripId).get();
    if (!tripDoc.exists || tripDoc.data().userId !== userId) {
      return null;
    }

    return activity;
  },

  async updateActivity(userId, id, data) {
    const db = getDb();
    const docRef = db.collection(COLLECTION_NAME).doc(id);
    const existing = await docRef.get();

    if (!existing.exists) {
      return null;
    }

    const current = existing.data();
    // Verify parent trip belongs to user
    const tripDoc = await db.collection('trips').doc(current.tripId).get();
    if (!tripDoc.exists || tripDoc.data().userId !== userId) {
      return null;
    }

    const now = new Date().toISOString();

    const updated = {
      ...current,
      ...(data.dayNumber !== undefined && { dayNumber: Number(data.dayNumber) }),
      ...(data.date !== undefined && { date: new Date(data.date).toISOString() }),
      ...(data.timeString !== undefined && { timeString: data.timeString.trim() }),
      ...(data.title !== undefined && { title: data.title.trim() }),
      ...(data.location !== undefined && { location: data.location.trim() }),
      ...(data.category !== undefined && { category: data.category.trim() }),
      ...(data.notes !== undefined && { notes: data.notes }),
      ...(data.latitude !== undefined && { latitude: data.latitude !== null ? Number(data.latitude) : null }),
      ...(data.longitude !== undefined && { longitude: data.longitude !== null ? Number(data.longitude) : null }),
      updatedAt: now,
    };

    await docRef.set(updated, { merge: true });
    return updated;
  },

  async deleteActivity(userId, id) {
    const db = getDb();
    const docRef = db.collection(COLLECTION_NAME).doc(id);
    const existing = await docRef.get();

    if (!existing.exists) {
      return null;
    }

    const current = existing.data();
    // Verify parent trip belongs to user
    const tripDoc = await db.collection('trips').doc(current.tripId).get();
    if (!tripDoc.exists || tripDoc.data().userId !== userId) {
      return null;
    }

    await docRef.delete();
    return { id, deleted: true };
  },
};

module.exports = activityService;
