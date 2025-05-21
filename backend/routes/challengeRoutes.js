// routes/challengeRoutes.js
const express = require('express');
const router = express.Router();
const challengeController = require('../controllers/challengeController');

// Admin-only
router.post('/', challengeController.createChallenge);
router.get('/', challengeController.getAllChallenges);
router.get('/:id', challengeController.getChallengeById);
router.put('/:id', challengeController.updateChallenge);
router.delete('/:id', challengeController.deleteChallenge);

// User interaction
router.post('/:id/submit', challengeController.submitChallenge);
router.post('/:id/join', challengeController.joinChallenge);

module.exports = router;
