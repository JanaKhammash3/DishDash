const express = require('express');
const router = express.Router();
const {
  createNotification,
  getNotifications,
  markAsRead,
  getUnreadCount,
  getUserNotifications,
} = require('../controllers/notificationController');

router.post('/', createNotification);

// ✅ Put this before /:userId
router.get('/:userId/unread-count', getUnreadCount);

// 📩 Get notifications by model
router.get('/:id/:model', getNotifications);

// ✅ This must be LAST
router.get('/:userId', getUserNotifications);

// ✅ Mark as read
router.patch('/read/:notificationId', markAsRead);

module.exports = router;
