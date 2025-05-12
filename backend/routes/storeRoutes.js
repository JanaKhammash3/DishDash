const express = require('express');
const router = express.Router();
const Store = require('../models/Store');
const multer = require('multer');
const upload = multer({ dest: 'uploads/' });


const {
  getNearbyStores,
  comparePrices,
  addStore,
  getStorePrices,
  addItemToStore,
  getStoreById,
} = require('../controllers/storeController');

// ➕ Add a new store
router.post('/add', addStore);

// 📦 Add item to specific store
router.post('/stores/:storeId/items', addItemToStore);

// 📍 Get nearby stores by coordinates
router.get('/nearby', getNearbyStores);

// 🔎 Get a store by ID
router.get('/stores/:storeId', getStoreById);

// 📊 Compare item prices across stores
router.get('/compare', comparePrices);

// 📦 Return flat list of all items across all stores (used in some screens)
router.get('/store-items', async (req, res) => {
  try {
    const stores = await Store.find();
    const allItems = stores.flatMap(store =>
      store.items.map(item => ({
        name: item.name,
        price: item.price,
        store: store.name,
      }))
    );
    res.json(allItems);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch store items' });
  }
});

// ✅ NEW: Return grouped store data for Flutter UI
router.get('/api/stores-with-items', async (req, res) => {
  try {
    const stores = await Store.find({}, 'name items image telephone'); // ✅ Add 'telephone'
    res.json(stores);
  } catch (err) {
    console.error('❌ Error fetching stores with items:', err);
    res.status(500).json({ error: 'Server error' });
  }
});



// ✅ NEW: Search stores by item name
router.get('/api/stores/search', async (req, res) => {
  const { item } = req.query;
  if (!item) return res.status(400).json({ error: 'Missing item query' });

  try {
    const stores = await Store.find({
      "items.name": { $regex: new RegExp(item, 'i') },
    });
    res.json(stores);
  } catch (err) {
    console.error('❌ Error in search:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// 🧮 (Optional) Keep this if used elsewhere
router.get('/api/stores', getStorePrices);


router.put('/stores/:storeId/image', upload.single('image'), async (req, res) => {
  try {
    const storeId = req.params.storeId;

    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const imageUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;

    const store = await Store.findById(storeId);
    if (!store) {
      return res.status(404).json({ error: 'Store not found' });
    }

    store.image = imageUrl;
    await store.save(); // ✅ Save the image URL manually

    console.log('✅ Image saved to store:', store.image);
    res.status(200).json(store);
  } catch (err) {
    console.error('❌ Error uploading image:', err);
    res.status(500).json({ error: 'Image upload failed' });
  }
});


module.exports = router;
