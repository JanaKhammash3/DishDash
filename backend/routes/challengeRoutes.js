const express = require('express');
const router = express.Router();
const challengeController = require('../controllers/challengeController');

// Admin
router.post('/', challengeController.createChallenge);
router.get('/', challengeController.getAllChallenges);
router.get('/:id', challengeController.getChallengeById);
router.put('/:id', challengeController.updateChallenge);
router.delete('/:id', challengeController.deleteChallenge);

// User interaction
router.post('/:id/join', challengeController.joinChallenge);
router.post('/:id/submit', challengeController.submitChallenge);

// Admin functionality
router.get('/:id/submissions', challengeController.getSubmissions);
router.put('/:id/score/:userId', challengeController.scoreSubmission);
router.post('/:id/winners', challengeController.setWinners);

module.exports = router;
