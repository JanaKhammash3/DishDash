const express = require('express');
const router = express.Router();
const postController = require('../controllers/postController');

router.get('/likes-count/:userId', postController.getUserLikesCount);

module.exports = router;
