const express = require('express');
const router = express.Router();
const { sendNotification, getUserNotifications, markAsSeen } = require('../controllers/notificationController');

router.post('/', sendNotification);
router.get('/:userId', getUserNotifications);
router.put('/:id/seen', markAsSeen);

module.exports = router;
