const express = require('express');
const router = express.Router();
const courseController = require('../controllers/courseController');
const upload = require('../middlewares/videoUpload');

router.post('/', courseController.createCourse);
router.get('/', courseController.getAllCourses);
router.post('/:id/rate', courseController.rateCourse);

// Upload single video (you can use this to upload episode videos separately)
router.post('/upload-video', upload.single('video'), courseController.uploadVideo);

module.exports = router;
