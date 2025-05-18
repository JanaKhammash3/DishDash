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
  getStoresWithItems,
  getStoreById,
  recordPurchase,
  rateStore 
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

// ✅ New controller-based version
router.get('/api/stores-with-items', getStoresWithItems);


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


router.patch('/stores/:storeId/image', upload.single('image'), async (req, res) => {
  try {
    const storeId = req.params.storeId;

    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const imageUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;

    const store = await Store.findByIdAndUpdate(
      storeId,
      { image: imageUrl },
      { new: true, runValidators: false }
    );

    if (!store) {
      return res.status(404).json({ error: 'Store not found' });
    }

    console.log('✅ Image saved to store:', store.image);
    res.status(200).json(store);
  } catch (err) {
    console.error('❌ Error uploading image:', err);
    res.status(500).json({ error: 'Image upload failed' });
  }
});


router.post('/:storeId/purchase', recordPurchase);

router.post('/stores/:storeId/rate', rateStore);
router.get('/', async (req, res) => {
  try {
    const stores = await Store.find();
    res.status(200).json(stores);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch stores', error: err.message });
  }
});


module.exports = router;
