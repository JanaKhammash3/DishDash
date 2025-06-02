const express = require('express');
const router = express.Router();
const {
  createNotification,
  getNotifications,
  markAsRead,
  getUnreadCount,
  getUserNotifications,
  deleteNotification, // 👈 Add this
  deleteAllNotificationsForRecipient,
} = require('../controllers/notificationController');

// ✅ POST route
router.post('/', createNotification);

// ✅ Most specific routes FIRST
router.get('/:userId/unread-count', getUnreadCount);  
router.get('/:id/:model', getNotifications);          
router.patch('/read/:notificationId', markAsRead);    

// ✅ General fallback LAST
router.get('/:userId', getUserNotifications);         
router.delete('/:notificationId', deleteNotification);

// Optional: Delete all for a recipient
router.delete('/recipient/:recipientId', deleteAllNotificationsForRecipient);


module.exports = router;
