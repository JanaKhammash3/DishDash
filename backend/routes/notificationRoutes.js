const express = require('express');
const router = express.Router();
const {
  createNotification,
  getNotifications,
  markAsRead,
  getUnreadCount,
  getUserNotifications,
} = require('../controllers/notificationController');

// ✅ POST route
router.post('/', createNotification);

// ✅ Most specific routes FIRST
router.get('/:id/:model', getNotifications);          
router.get('/:userId/unread-count', getUnreadCount);  
router.patch('/read/:notificationId', markAsRead);    

// ✅ General fallback LAST
router.get('/:userId', getUserNotifications);         



module.exports = router;
