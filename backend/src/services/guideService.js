const { getDb } = require('./db');

const COLLECTION_NAME = 'guides';

const INITIAL_GUIDES = [
  {
    id: 'guide-1',
    name: 'Wayan Sudra',
    tourTitle: 'Uluwatu Sunset Tour',
    location: 'Uluwatu, Bali',
    category: 'Culture',
    rating: 4.8,
    reviewsCount: 1200,
    pricePerPerson: 1500.0,
    description: 'Born and raised in Uluwatu, specializing in clifftop temple folklore, traditional Kecak fire dance secrets, and secluded sunset vistas.',
    imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
    languages: ['English', 'Indonesian', 'Balinese'],
    isFavorite: true,
    latitude: -8.8291,
    longitude: 115.0848,
  },
  {
    id: 'guide-2',
    name: 'Made Artha',
    tourTitle: 'Local Food Tour',
    location: 'Ubud & Denpasar',
    category: 'Food',
    rating: 4.7,
    reviewsCount: 856,
    pricePerPerson: 1200.0,
    description: 'Passionate culinary explorer taking you off the tourist trail into secret night markets, authentic roast suckling pork (Babi Guling), and spice gardens.',
    imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
    languages: ['English', 'Indonesian'],
    isFavorite: false,
    latitude: -8.5069,
    longitude: 115.2625,
  },
  {
    id: 'guide-3',
    name: 'Ketut Sujana',
    tourTitle: 'Bali Cultural Tour',
    location: 'Central Bali',
    category: 'Culture',
    rating: 4.9,
    reviewsCount: 1100,
    pricePerPerson: 1800.0,
    description: 'Historian and traditional artisan sharing deep insights into UNESCO heritage water temples, rice terrace subak irrigation, and ancient royal palaces.',
    imageUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=400&q=80',
    languages: ['English', 'Indonesian'],
    isFavorite: false,
    latitude: -8.3405,
    longitude: 115.0920,
  },
  {
    id: 'guide-4',
    name: 'Gede Pratama',
    tourTitle: 'Mount Batur Sunrise Trek',
    location: 'Kintamani, Bali',
    category: 'Adventure',
    rating: 4.9,
    reviewsCount: 2300,
    pricePerPerson: 2200.0,
    description: 'Certified mountain guide with 8+ years leading volcano treks, volcanic steam cooking experiences, and crater rim explorations.',
    imageUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=400&q=80',
    languages: ['English', 'Indonesian', 'Japanese'],
    isFavorite: true,
    latitude: -8.2422,
    longitude: 115.3756,
  },
];

/**
 * Service managing Firestore queries for Local Guides
 */
const guideService = {
  async ensureGuidesSeeded() {
    const db = getDb();
    const snapshot = await db.collection(COLLECTION_NAME).get();

    if (snapshot.empty) {
      const now = new Date().toISOString();
      for (const guide of INITIAL_GUIDES) {
        await db.collection(COLLECTION_NAME).doc(guide.id).set({
          ...guide,
          createdAt: now,
          updatedAt: now,
        });
      }
    }
  },

  async getGuides(query = {}) {
    await this.ensureGuidesSeeded();
    const db = getDb();
    const snapshot = await db.collection(COLLECTION_NAME).get();

    let guides = [];
    snapshot.forEach((doc) => {
      guides.push(doc.data());
    });

    if (query.category && query.category.toLowerCase() !== 'all') {
      const cat = query.category.toLowerCase();
      guides = guides.filter((g) => g.category && g.category.toLowerCase() === cat);
    }

    if (query.search && query.search.trim()) {
      const term = query.search.trim().toLowerCase();
      guides = guides.filter(
        (g) =>
          (g.name && g.name.toLowerCase().includes(term)) ||
          (g.tourTitle && g.tourTitle.toLowerCase().includes(term)) ||
          (g.location && g.location.toLowerCase().includes(term))
      );
    }

    return guides;
  },

  async getGuideById(id) {
    await this.ensureGuidesSeeded();
    const db = getDb();
    const docRef = db.collection(COLLECTION_NAME).doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return null;
    }
    return doc.data();
  },
};

module.exports = guideService;
