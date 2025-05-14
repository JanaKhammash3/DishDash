// controllers/storeController.js
const Store = require('../models/Store');

exports.getNearbyStores = async (req, res) => {
  try {
    const stores = await Store.find();
    res.status(200).json(stores);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.comparePrices = async (req, res) => {
  try {
    const itemName = req.query.item;
    if (!itemName) {
      return res.status(400).json({ message: 'Missing item query parameter' });
    }

    const stores = await Store.find({ 'items.name': itemName });
    const results = stores.map(store => {
      const item = store.items.find(i => i.name === itemName);
      return { store: store.name, price: item.price };
    }).filter(r => r.price !== undefined);

    results.sort((a, b) => a.price - b.price);
    res.status(200).json(results);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.addStore = async (req, res) => {
  try {
   const { name, location, items, image } = req.body;

const newStore = await Store.create({
  name,
  location,
  items,
  image, // ✅ include this
});


    res.status(201).json(newStore);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.getStorePrices = async (req, res) => {
  const { item } = req.query;

  if (!item) return res.status(400).json({ error: 'Item is required' });

  try {
    const stores = await Store.find(
      { "items.name": item },
      'name location items image'
    );

    console.log('🔍 Returned stores with images:', stores); // Add this

    res.json(stores);
  } catch (err) {
    console.error('❌ Error fetching store prices:', err);
    res.status(500).json({ error: 'Server error' });
  }
};



// POST /api/stores/:storeId/items
exports.addItemToStore = async (req, res) => {
  const { storeId } = req.params;
  const { name, price } = req.body;

  if (!name || price == null) {
    return res.status(400).json({ message: 'Name and price are required' });
  }

  try {
    const store = await Store.findById(storeId);
    if (!store) return res.status(404).json({ message: 'Store not found' });

    const existingItem = store.items.find(
      item => item.name.toLowerCase() === name.toLowerCase()
    );

    if (existingItem) {
      return res.status(400).json({ message: 'Item already exists in the store' });
    }

    store.items.push({ name, price });
    await store.save();

    res.status(200).json({ message: 'Item added', items: store.items });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};


exports.getStoreById = async (req, res) => {
  try {
    const store = await Store.findById(req.params.storeId);
    if (!store) return res.status(404).json({ message: 'Store not found' });

    res.status(200).json(store); // ✅ Return full store object
  } catch (err) {
    console.error('Get store error:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.recordPurchase = async (req, res) => {
  const { storeId } = req.params;
  const { userId, ingredient } = req.body;

  if (!userId || !ingredient) {
    return res.status(400).json({ message: 'userId and ingredient are required' });
  }

  try {
    const store = await Store.findById(storeId);
    if (!store) return res.status(404).json({ message: 'Store not found' });

    // ✅ Prevent duplicate purchase entries
    const alreadyPurchased = store.purchases.some(p =>
      p.userId.toString() === userId && p.ingredient.toLowerCase() === ingredient.toLowerCase()
    );

    if (alreadyPurchased) {
      return res.status(200).json({ message: 'Purchase already recorded' });
    }

    store.purchases.push({ userId, ingredient });
    await store.save();

    res.status(200).json({ message: 'Purchase recorded successfully' });
  } catch (err) {
    console.error('❌ Error recording purchase:', err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};


exports.getStoresWithItems = async (req, res) => {
  const { lat, lng } = req.query;

  try {
    const stores = await Store.find().lean();

    const enriched = stores.map(store => {
      // 📍 Distance calculation
      let distance = null;
      if (lat && lng && store.location) {
        const R = 6371; // Radius of Earth in km
        const dLat = deg2rad(store.location.lat - lat);
        const dLon = deg2rad(store.location.lng - lng);
        const a =
          Math.sin(dLat / 2) ** 2 +
          Math.cos(deg2rad(lat)) * Math.cos(deg2rad(store.location.lat)) *
          Math.sin(dLon / 2) ** 2;
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        distance = R * c;
      }

      // ⭐ Average rating
      const ratings = store.ratings || [];
      const avgRating = ratings.length
        ? ratings.reduce((sum, r) => sum + r.value, 0) / ratings.length
        : null;

      return {
        _id: store._id,
        name: store.name,
        image: store.image,
        telephone: store.telephone,
        location: store.location, // ✅ Add this line
        items: store.items,
        distance: distance ? Number(distance.toFixed(2)) : null,
        avgRating: avgRating ? Number(avgRating.toFixed(1)) : null,
      };
    });

    res.json(enriched);
  } catch (err) {
    console.error('❌ Error in getStoresWithItems:', err.message);
    res.status(500).json({ error: 'Failed to fetch store data' });
  }
};

function deg2rad(deg) {
  return deg * (Math.PI / 180);
}


exports.rateStore = async (req, res) => {
  const { storeId } = req.params;
  let { userId, value } = req.body;

  value = Number(value);
  if (!userId || isNaN(value) || value < 1 || value > 5) {
    return res.status(400).json({ error: 'Invalid input. userId and value (1-5) are required.' });
  }

  try {
    const store = await Store.findById(storeId);
    if (!store) return res.status(404).json({ error: 'Store not found' });

    const existing = store.ratings.find(r => r.userId.toString() === userId);

    if (existing) {
      // Update existing rating directly without full document validation
      await Store.updateOne(
        { _id: storeId, "ratings.userId": userId },
        { $set: { "ratings.$.value": value } }
      );
      console.log('🔁 Updated existing rating');
    } else {
      // Push new rating using update to avoid validation errors on unrelated fields
      await Store.updateOne(
        { _id: storeId },
        { $push: { ratings: { userId, value } } }
      );
      console.log('➕ Added new rating');
    }

    // Re-fetch to get updated rating list
    const updatedStore = await Store.findById(storeId);
    const avg = updatedStore.ratings.reduce((s, r) => s + r.value, 0) / updatedStore.ratings.length;

    return res.status(200).json({ avgRating: avg.toFixed(1) });

  } catch (err) {
    console.error('❌ Error in rateStore:', err);
    return res.status(500).json({ error: 'Failed to save rating', details: err.message });
  }
};

