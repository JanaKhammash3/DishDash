const Notification = require('../models/Notification');

const mongoose = require('mongoose');

const createNotification = async (req, res) => {
  try {
    console.log('📨 Incoming notification body:', req.body);

    const {
      recipientId,
      recipientModel,
      senderId,
      senderModel,
      type,
      message,
      relatedId,
    } = req.body;

    const notificationData = {
      recipientId: new mongoose.Types.ObjectId(recipientId),
      recipientModel,
      senderId: new mongoose.Types.ObjectId(senderId),
      senderModel,
      type,
      message,
    };

    // Handle relatedId (ObjectId or string)
    if (relatedId) {
      try {
        notificationData.relatedId = new mongoose.Types.ObjectId(relatedId);
      } catch {
        // fallback to string
        notificationData.relatedId = relatedId;
      }
    }

    const newNotification = new Notification(notificationData);
    await newNotification.save();

    res.status(201).json({ message: 'Notification sent', notification: newNotification });
  } catch (err) {
    console.error('❌ Notification Error:', err.message);
    res.status(500).json({ error: 'Failed to send notification', details: err.message });
  }
};


const getNotifications = async (req, res) => {
  try {
    const { id, model } = req.params;

    console.log(`📩 Fetching notifications for id: ${id}, model: ${model}`);

    const notifications = await Notification.find({
      recipientId: id, // ✅ remove ObjectId wrapping
      recipientModel: model, // must be exactly 'Store'
    })
    .populate('senderId', 'name avatar') // ✅ already correct
    .sort({ createdAt: -1 });

    console.log('✅ Sample sender:', notifications[0]?.senderId);
    res.status(200).json(notifications);
  } catch (err) {
    console.error('❌ Error fetching notifications:', err);
    res.status(500).json({ message: 'Server error' });
  }
};




const markAsRead = async (req, res) => {
  try {
    const { notificationId } = req.params;
    await Notification.findByIdAndUpdate(notificationId, { isRead: true });
    res.json({ message: 'Notification marked as read' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to update notification', details: err.message });
  }
};

const getUnreadCount = async (req, res) => {
  try {
    const { userId } = req.params;
    const count = await Notification.countDocuments({
      recipientId: userId,
      isRead: false,
    });
    res.json({ count });
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

const deleteNotification = async (req, res) => {
  try {
    const { notificationId } = req.params;

    const deleted = await Notification.findByIdAndDelete(notificationId);

    if (!deleted) {
      return res.status(404).json({ message: 'Notification not found' });
    }

    res.json({ message: 'Notification deleted successfully' });
  } catch (err) {
    console.error('❌ Error deleting notification:', err.message);
    res.status(500).json({ error: 'Failed to delete notification', details: err.message });
  }
};

const deleteAllNotificationsForRecipient = async (req, res) => {
  try {
    const { recipientId } = req.params;

    await Notification.deleteMany({ recipientId });

    res.json({ message: 'All notifications deleted for this recipient' });
  } catch (err) {
    console.error('❌ Error deleting all notifications:', err.message);
    res.status(500).json({ error: 'Failed to delete notifications', details: err.message });
  }
};


module.exports = {
  createNotification,
  getNotifications,
  markAsRead,
  getUnreadCount,
  getUserNotifications,
  deleteNotification,
  deleteAllNotificationsForRecipient
};

