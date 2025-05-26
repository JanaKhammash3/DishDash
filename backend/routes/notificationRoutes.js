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

// ✅ Specific routes first
router.get('/:userId/unread-count', getUnreadCount);
router.get('/:id/:model', getNotifications);   // model-based comes first
router.patch('/read/:notificationId', markAsRead);

// ✅ General fallback LAST
router.get('/:userId', getUserNotifications);

module.exports = router;
