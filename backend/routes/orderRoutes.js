const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');

// Create a new order
router.post('/create', orderController.createOrder);

// Get all orders by user
router.get('/user/:userId', orderController.getUserOrders);

// Get all orders by store
router.get('/store/:storeId', orderController.getStoreOrders);

// Update order status
router.put('/:orderId/status', orderController.updateOrderStatus);

module.exports = router;
