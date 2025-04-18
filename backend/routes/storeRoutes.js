// routes/storeRoutes.js
const express = require('express');
const router = express.Router();
const { getNearbyStores, comparePrices } = require('../controllers/storeController');

router.get('/nearby', getNearbyStores);
router.get('/compare', comparePrices);

module.exports = router;