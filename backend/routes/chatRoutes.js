const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');

router.get('/unread-count/:userId', chatController.getUnreadCount); // ⬅️ must come BEFORE
router.get('/users/:userId', chatController.getChatUsers);
router.post('/send', chatController.sendMessage);
router.post('/markAsRead', chatController.markMessagesAsRead);
router.get('/:userId/:otherUserId', chatController.getConversation); // ⬅️ this last

module.exports = router;
