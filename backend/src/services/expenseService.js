const crypto = require('crypto');
const { getDb } = require('./db');

const COLLECTION_NAME = 'expenses';

/**
 * Service managing Firestore CRUD operations for Expenses
 * strictly scoped to the authenticated user's trips.
 */
const expenseService = {
  async createExpense(userId, tripId, data) {
    const db = getDb();

    // Verify parent trip belongs to the authenticated user
    const tripDoc = await db.collection('trips').doc(tripId).get();
    if (!tripDoc.exists || tripDoc.data().userId !== userId) {
      return null;
    }

    const id = data.id || `exp-${crypto.randomUUID().slice(0, 8)}`;
    const now = new Date().toISOString();

    const newExpense = {
      id,
      tripId,
      userId,
      title: data.title.trim(),
      amount: Number(data.amount),
      category: data.category.trim(),
      date: new Date(data.date).toISOString(),
      notes: data.notes || null,
      createdAt: now,
      updatedAt: now,
    };

    const docRef = db.collection(COLLECTION_NAME).doc(id);
    await docRef.set(newExpense);
    return newExpense;
  },

  async getExpensesByTripId(userId, tripId) {
    const db = getDb();

    // Verify parent trip belongs to the authenticated user
    const tripDoc = await db.collection('trips').doc(tripId).get();
    if (!tripDoc.exists || tripDoc.data().userId !== userId) {
      return null;
    }

    const snapshot = await db.collection(COLLECTION_NAME).where('tripId', '==', tripId).get();
    const expenses = [];
    snapshot.forEach((doc) => {
      expenses.push(doc.data());
    });

    // Sort by date descending (newest first)
    expenses.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
    return expenses;
  },

  async getExpenseById(userId, id) {
    const db = getDb();
    const docRef = db.collection(COLLECTION_NAME).doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return null;
    }

    const expense = doc.data();
    // Verify parent trip belongs to user
    const tripDoc = await db.collection('trips').doc(expense.tripId).get();
    if (!tripDoc.exists || tripDoc.data().userId !== userId) {
      return null;
    }

    return expense;
  },

  async updateExpense(userId, id, data) {
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
      ...(data.title !== undefined && { title: data.title.trim() }),
      ...(data.amount !== undefined && { amount: Number(data.amount) }),
      ...(data.category !== undefined && { category: data.category.trim() }),
      ...(data.date !== undefined && { date: new Date(data.date).toISOString() }),
      ...(data.notes !== undefined && { notes: data.notes }),
      updatedAt: now,
    };

    await docRef.set(updated, { merge: true });
    return updated;
  },

  async deleteExpense(userId, id) {
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

module.exports = expenseService;
