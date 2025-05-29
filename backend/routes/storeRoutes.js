const express = require('express');
const router = express.Router();
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
  rateStore,
  getAllStores,
  updateStoreItem,
  deleteStoreItem,
  deleteStore
} = require('../controllers/storeController');

const Store = require('../models/Store');

// ➕ Add a new store
router.post('/add', addStore);

// 🔍 Get stores with items (used for grocery/store mapping)
router.get('/api/stores-with-items', getStoresWithItems);

// 🔍 Get a store by ID
router.get('/stores/:storeId', getStoreById);

// 📍 Get nearby stores by coordinates
router.get('/nearby', getNearbyStores);

// 📊 Compare item prices across stores
router.get('/compare', comparePrices);

// 📦 Return flat list of all items across all stores
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

// 🛒 Record purchase for a store
router.post('/:storeId/purchase', recordPurchase);

// ⭐ Rate store
router.post('/stores/:storeId/rate', rateStore);

// 📷 Upload or update store image
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

// 📥 Get all items for a specific store
router.get('/stores/:storeId/items', async (req, res) => {
  try {
    const store = await Store.findById(req.params.storeId);
    if (!store) return res.status(404).json({ error: 'Store not found' });

    res.json(store.items);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch store items', detail: err.message });
  }
});

// ➕ Add item to specific store
router.post('/:storeId/add-item', addItemToStore);

// ✏️ Update store item
router.put('/stores/:storeId/items/:itemId', updateStoreItem);

// 🗑️ Delete store item
router.delete('/stores/:storeId/items/:itemId', deleteStoreItem);

// 🔍 Search stores by item name
router.get('/api/stores/search', async (req, res) => {
  const { item } = req.query;
  if (!item) return res.status(400).json({ error: 'Missing item query' });

  try {
    const stores = await Store.find({
      "items.name": { $regex: new RegExp(item, 'i') },
    });
    res.json(stores);
  } catch (err) {
    console.error('❌ Error in item-based search:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// ✅ Simple GET /stores route for search by name/email
router.get('/stores', getAllStores);

router.delete('/stores/:storeId', deleteStore);

module.exports = router;
