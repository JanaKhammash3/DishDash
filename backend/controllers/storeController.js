// controllers/storeController.js
const mongoose = require('mongoose');

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
    const {
      name,
      email,
      password,
      telephone,
      location,
      image,
      items = [], // allow optional initial items
      openHours
    } = req.body;

    const store = new Store({
      name,
      email,
      password,
      telephone,
      location,
      image,
      openHours,
      items: items.map(item => ({
        ...item,
        _id: new mongoose.Types.ObjectId() // ensure item has a unique ID
      }))
    });

    await store.save();

    res.status(201).json({ message: 'Store registered successfully', store });
  } catch (err) {
    console.error('❌ Store registration failed:', err);
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

// ➕ Add item to store
const addItemToStore = async (req, res) => {
  try {
    const { storeId } = req.params;
    const { name, price, status, category } = req.body;

    if (!name || price == null || !status || !category) {
      return res.status(400).json({ error: 'All fields are required' });
    }

    const newItem = {
      _id: new mongoose.Types.ObjectId(),
      name,
      price,
      status,
      category
    };

    const store = await Store.findById(storeId);
    if (!store) return res.status(404).json({ error: 'Store not found' });

    await Store.updateOne(
      { _id: storeId },
      { $push: { items: newItem } }
    );

    res.status(200).json({ message: 'Item added successfully', item: newItem });
  } catch (err) {
    console.error('❌ Error adding item:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// ✅ Make sure to export this
exports.addItemToStore = addItemToStore;


exports.getStoreById = async (req, res) => {
  try {
const store = await Store.findById(req.params.storeId)
  .populate('purchases.userId', 'name avatar');
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

  // ✅ Check required fields
  if (!userId || !ingredient) {
    return res.status(400).json({
      message: 'userId and ingredient are required',
    });
  }

  try {
    const store = await Store.findById(storeId);
    if (!store) {
      return res.status(404).json({ message: 'Store not found' });
    }

    // ✅ Ensure purchases array exists
    const purchases = store.purchases || [];

    // ✅ Prevent duplicate purchase entries
    const alreadyPurchased = purchases.some((p) =>
      p?.userId?.toString() === userId &&
      p?.ingredient?.toLowerCase() === ingredient.toLowerCase()
    );

    if (alreadyPurchased) {
      return res.status(200).json({ message: 'Purchase already recorded' });
    }

    // ✅ Push new purchase
    store.purchases.push({ userId, ingredient });

    await store.save({ validateBeforeSave: false });

    return res.status(200).json({ message: 'Purchase recorded successfully' });
  } catch (err) {
    console.error('❌ Error recording purchase:', err);
    return res.status(500).json({
      message: 'Server error',
      error: err.message,
    });
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
            location: store.location,
            items: store.items,
            distance: distance ? Number(distance.toFixed(2)) : null,
            avgRating: avgRating ? Number(avgRating.toFixed(1)) : null,
            openHours: store.openHours, // ✅ Add this line
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

exports.updateStoreItem = async (req, res) => {
  const { storeId, itemId } = req.params;
  const { name, price, image, category, status } = req.body;

  try {
    const store = await Store.findById(storeId);
    if (!store) return res.status(404).json({ message: 'Store not found' });

    // Find the item in the embedded items array
    const item = store.items.id(itemId);
    if (!item) return res.status(404).json({ message: 'Item not found' });

    // Update only provided fields
    if (name !== undefined) item.name = name;
    if (price !== undefined) item.price = price;
    if (image !== undefined) item.image = image;
    if (category !== undefined) item.category = category;
    if (status !== undefined) item.status = status;

    // Save the parent document (Store)
    await store.save({ validateBeforeSave: false });

    res.status(200).json({ message: '✅ Item updated successfully', item });
  } catch (err) {
    console.error('❌ Error updating item:', err.message);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};


exports.deleteStoreItem = async (req, res) => {
  const { storeId, itemId } = req.params;

  try {
    // Fetch store by ID
    const store = await Store.findById(storeId);
    if (!store) {
      return res.status(404).json({ message: 'Store not found' });
    }

    // Check if item exists
    const itemExists = store.items.some(
      item => item._id.toString() === itemId
    );
    if (!itemExists) {
      return res.status(404).json({ message: 'Item not found in store' });
    }

    // Remove the item from the embedded array
    store.items.pull({ _id: itemId });

    // Save without triggering full schema validation
    await store.save({ validateBeforeSave: false });

    res.status(200).json({ message: 'Item deleted successfully' });
  } catch (err) {
    console.error('❌ Error deleting item:', err.message);
    res.status(500).json({
      message: 'Server error',
      error: err.message,
    });
  }
};

// ✅ GET /api/stores?search=
// ✅ GET /api/stores?search=&sort=name|rating
exports.getAllStores = async (req, res) => {
  try {
    const { search = '', sort = 'name' } = req.query;

    const query = {
      $or: [
        { name: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
      ]
    };

    const stores = await Store.find(query).lean();

    // Calculate avgRating for each store
    for (let store of stores) {
      const ratings = store.ratings || [];
      store.avgRating = ratings.length
        ? ratings.reduce((sum, r) => sum + (r.value || 0), 0) / ratings.length
        : 0;
    }

    // Sort
    if (sort === 'rating') {
      stores.sort((a, b) => b.avgRating - a.avgRating); // high to low
    } else {
      stores.sort((a, b) => a.name.localeCompare(b.name)); // A-Z
    }

    res.status(200).json(stores);
  } catch (err) {
    console.error('❌ Error in getAllStores:', err.message);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};
// 🗑️ Delete a store
// storeController.js

exports.deleteStore = async (req, res) => {
  try {
    const { storeId } = req.params;

    const store = await Store.findByIdAndDelete(storeId);

    if (!store) {
      return res.status(404).json({ error: 'Store not found' });
    }

    res.status(200).json({ message: '✅ Store deleted successfully.' });
  } catch (err) {
    console.error('❌ Error deleting store:', err.message);
    res.status(500).json({ error: 'Server error', detail: err.message });
  }
};

