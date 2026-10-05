const crypto = require('crypto');
const { getFirestoreDb } = require('../config/firebase');

/**
 * In-memory collection simulator implementing Firestore CollectionReference and DocumentReference
 * contracts for test execution and offline development.
 */
class InMemoryCollection {
  constructor(name, store) {
    this.name = name;
    this.store = store; // Map<id, docData>
  }

  doc(id) {
    const docId = id || crypto.randomUUID();
    const self = this;

    return {
      id: docId,
      async get() {
        const data = self.store.get(docId);
        return {
          id: docId,
          exists: data !== undefined,
          data() {
            return data ? JSON.parse(JSON.stringify(data)) : undefined;
          },
        };
      },
      async set(data, options = {}) {
        let finalData;
        if (options.merge && self.store.has(docId)) {
          finalData = { ...self.store.get(docId), ...data };
        } else {
          finalData = { ...data, id: docId };
        }
        self.store.set(docId, finalData);
        return finalData;
      },
      async update(data) {
        if (!self.store.has(docId)) {
          const err = new Error(`No document found with ID ${docId}`);
          err.code = 5; // NOT_FOUND
          throw err;
        }
        const updated = { ...self.store.get(docId), ...data };
        self.store.set(docId, updated);
        return updated;
      },
      async delete() {
        self.store.delete(docId);
        return { success: true };
      },
    };
  }

  async add(data) {
    const docId = data.id || crypto.randomUUID();
    const docRef = this.doc(docId);
    await docRef.set({ ...data, id: docId });
    return docRef;
  }

  where(field, op, val) {
    return new InMemoryQuery(this, [(item) => {
      if (op === '==') return item[field] === val;
      if (op === '>=') return item[field] >= val;
      if (op === '<=') return item[field] <= val;
      if (op === '>') return item[field] > val;
      if (op === '<') return item[field] < val;
      if (op === 'in') return Array.isArray(val) && val.includes(item[field]);
      return false;
    }]);
  }

  orderBy(field, direction = 'asc') {
    return new InMemoryQuery(this, [], { field, direction });
  }

  async get() {
    return new InMemoryQuery(this, []).get();
  }
}

class InMemoryQuery {
  constructor(collection, filters = [], order = null) {
    this.collection = collection;
    this.filters = filters;
    this.order = order;
  }

  where(field, op, val) {
    const filterFn = (item) => {
      if (op === '==') return item[field] === val;
      if (op === '>=') return item[field] >= val;
      if (op === '<=') return item[field] <= val;
      if (op === '>') return item[field] > val;
      if (op === '<') return item[field] < val;
      if (op === 'in') return Array.isArray(val) && val.includes(item[field]);
      return false;
    };
    return new InMemoryQuery(this.collection, [...this.filters, filterFn], this.order);
  }

  orderBy(field, direction = 'asc') {
    return new InMemoryQuery(this.collection, this.filters, { field, direction });
  }

  async get() {
    let items = Array.from(this.collection.store.values());

    for (const filterFn of this.filters) {
      items = items.filter(filterFn);
    }

    if (this.order) {
      const { field, direction } = this.order;
      items.sort((a, b) => {
        if (a[field] < b[field]) return direction === 'asc' ? -1 : 1;
        if (a[field] > b[field]) return direction === 'asc' ? 1 : -1;
        return 0;
      });
    }

    const docs = items.map((item) => ({
      id: item.id,
      exists: true,
      data: () => JSON.parse(JSON.stringify(item)),
    }));

    return {
      docs,
      empty: docs.length === 0,
      size: docs.length,
      forEach(cb) {
        docs.forEach(cb);
      },
    };
  }
}

class InMemoryFirestore {
  constructor() {
    this.collections = new Map();
  }

  collection(name) {
    if (!this.collections.has(name)) {
      this.collections.set(name, new Map());
    }
    return new InMemoryCollection(name, this.collections.get(name));
  }

  clear() {
    this.collections.clear();
  }
}

// Global in-memory test store
const inMemoryDb = new InMemoryFirestore();
let testModeEnabled = process.env.NODE_ENV === 'test';

/**
 * Returns the active Firestore database.
 * If live Firestore is initialized, returns the Firebase Firestore instance.
 * If in test mode or memory store is requested, returns the in-memory simulator.
 * If neither is configured, throws a 503 Service Unavailable error.
 */
function getDb() {
  // Test-safe isolated store strictly for automated test execution
  if (testModeEnabled) {
    return inMemoryDb;
  }

  // Normal development and production always use real Firestore
  const liveFirestore = getFirestoreDb();
  if (liveFirestore) {
    return liveFirestore;
  }

  const error = new Error('Firebase Firestore is not configured. Please configure FIREBASE_SERVICE_ACCOUNT_PATH in .env');
  error.statusCode = 503;
  throw error;
}

function enableTestMode(enabled = true) {
  testModeEnabled = enabled;
}

function clearInMemoryDb() {
  inMemoryDb.clear();
}

module.exports = {
  getDb,
  enableTestMode,
  clearInMemoryDb,
  inMemoryDb,
};
