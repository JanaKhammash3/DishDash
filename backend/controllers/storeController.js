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

  try {
    const store = await Store.findById(storeId);
    if (!store) return res.status(404).json({ message: 'Store not found' });

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


