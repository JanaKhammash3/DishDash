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
    const { name, location, items } = req.body;

    const newStore = await Store.create({
      name,
      location,
      items,
    });

    res.status(201).json(newStore);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

// Example: controllers/storeController.js
exports.getStorePrices = async (req, res) => {
  const { item } = req.query;

  if (!item) {
    return res.status(400).json({ error: 'Item is required' });
  }

  try {
    const stores = await Store.find({ "items.name": item }); // or .find() then filter in JS
    res.json(stores);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
};
