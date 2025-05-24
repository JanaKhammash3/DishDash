const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');

router.post('/send', chatController.sendMessage);
router.get('/users/:userId', chatController.getChatUsers);
router.get('/:userId/:otherUserId', chatController.getConversation);
router.post('/markAsRead', chatController.markMessagesAsRead);
module.exports = router;
