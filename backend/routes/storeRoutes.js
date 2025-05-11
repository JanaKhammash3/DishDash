// routes/storeRoutes.js
const express = require('express');
const router = express.Router();
const { getNearbyStores, comparePrices, addStore, getStorePrices  } = require('../controllers/storeController');

router.post('/add', addStore);
// Example: routes/storeRoutes.js
router.get('/api/stores', getStorePrices);
router.get('/nearby', getNearbyStores);
router.get('/api/stores', async (req, res) => {
  const { item } = req.query;

  if (!item) return res.status(400).json({ error: 'Missing item query' });

  try {
    const stores = await Store.find({
      "items.name": { $regex: new RegExp(item, 'i') }
    });
    res.json(stores);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

router.get('/compare', comparePrices);


module.exports = router;