const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');

router.post('/send', chatController.sendMessage);
router.get('/:userId/:otherUserId', chatController.getConversation);

module.exports = router;
