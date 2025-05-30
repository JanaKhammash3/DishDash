const express = require('express');
const router = express.Router();
const courseController = require('../controllers/courseController');
const upload = require('../middlewares/videoUpload');
const { imageStorage } = require('../config/Cloudinary');
const multer = require('multer');
const uploadImage = multer({ storage: imageStorage });
router.post('/', courseController.createFromSingleVideo);
router.get('/', courseController.getAllCourses);
router.post('/:id/rate', courseController.rateCourse);

// Upload single video (you can use this to upload episode videos separately)
router.post('/upload-video', upload.single('video'), courseController.uploadVideo);
router.post(
  '/create-from-single-video',
  uploadImage.fields([
    { name: 'chefAvatar', maxCount: 1 },
    { name: 'image', maxCount: 1 }
  ]),
  courseController.createFromSingleVideo
);
module.exports = router;
