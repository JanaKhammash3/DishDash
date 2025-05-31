const Order = require('../models/Order');
const Notification = require('../models/Notification');

exports.createOrder = async (req, res) => {
  try {
    const { userId, storeId, items, deliveryMethod = 'Pickup' } = req.body;

    if (!userId || !storeId || !items || items.length === 0) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const total = items.reduce((sum, item) => sum + item.price * item.quantity, 0);

    const order = await Order.create({
      userId,
      storeId,
      items,
      total,
      paymentStatus: 'Paid', // Since it's a fake payment
      deliveryMethod,
      status: 'Placed'
    });

    res.status(201).json({ message: '✅ Order created', order });
  } catch (err) {
    console.error('❌ Error creating order:', err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.getUserOrders = async (req, res) => {
  try {
    const { userId } = req.params;

    const orders = await Order.find({ userId }).sort({ createdAt: -1 }).populate('storeId', 'name image');
    res.status(200).json(orders);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.getStoreOrders = async (req, res) => {
  try {
    const { storeId } = req.params;

    const orders = await Order.find({ storeId })
      .sort({ createdAt: -1 })
      .populate('userId', 'name avatar location'); // 🟢 added location

    res.status(200).json(orders);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};


// orderController.js
exports.updateOrderStatus = async (req, res) => {
  const { orderId } = req.params; // ✅ FIXED
  const { status } = req.body;

  if (!status) {
    return res.status(400).json({ message: 'Status is required' });
  }

  try {
    const order = await Order.findByIdAndUpdate(orderId, { status }, { new: true });

    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    res.status(200).json(order);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};
