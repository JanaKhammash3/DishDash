// routes/challengeRoutes.js
const express = require('express');
const router = express.Router();
const { createChallenge, getChallenges, participateInChallenge } = require('../controllers/challengeController');

router.post('/', createChallenge);
router.get('/', getChallenges);
router.post('/:id/participate', participateInChallenge);

module.exports = router;
