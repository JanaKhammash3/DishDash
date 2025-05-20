const Notification = require('../models/Notification');

// 🔔 Create and send a new notification
const createNotification = async (req, res) => {
  try {
    const {
      recipientId,
      recipientModel,
      senderId,
      senderModel,
      type,
      message,
      relatedId,
    } = req.body;

    const newNotification = new Notification({
      recipientId,
      recipientModel,
      senderId,
      senderModel,
      type,
      message,
      relatedId,
    });

    await newNotification.save();

    res.status(201).json({ message: 'Notification sent', notification: newNotification });
  } catch (err) {
    res.status(500).json({ error: 'Failed to send notification', details: err.message });
  }
};

// 📩 Get notifications for a specific user/store/admin
const getNotifications = async (req, res) => {
  try {
    const { id, model } = req.params;

    const notifications = await Notification.find({
      recipientId: id,
      recipientModel: model,
    }).sort({ createdAt: -1 });

    res.json(notifications);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch notifications', details: err.message });
  }
};

// ✅ Mark a notification as read
const markAsRead = async (req, res) => {
  try {
    const { notificationId } = req.params;

    await Notification.findByIdAndUpdate(notificationId, { isRead: true });

    res.json({ message: 'Notification marked as read' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to update notification', details: err.message });
  }
};
const getUnreadCount  = async (req, res) => {
  try {
    const { userId } = req.params;

    const count = await Notification.countDocuments({
      recipientId: userId,
      isRead: false,
    });

    res.json({ count }); // ✅ Return as an object
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};
const getUserNotifications = async (req, res) => {
  try {
    const { userId } = req.params;
    const notifications = await Notification.find({
      recipientId: userId,
    }).populate('senderId', 'name avatar').sort({ createdAt: -1 });
    
    res.json(notifications);
  } catch (error) {
    console.error('❌ Error fetching notifications:', error.message);
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = {
  createNotification,
  getNotifications,
  markAsRead,
  getUnreadCount,
  getUserNotifications,
};
