const Course = require('../models/Course');
const { cloudinary } = require('../config/Cloudinary'); // OR: require('cloudinary').v2
const fs = require('fs');


exports.createFromSingleVideo = async (req, res) => {
  try {
    const {
      title,
      description,
      videoUrl,
      fullDuration,
      chefName,
    } = req.body;

    const lessonDuration = 120;
    const episodeCount = Math.ceil(fullDuration / lessonDuration);

    const chefAvatarFile = req.files?.chefAvatar?.[0];
    const imageFile = req.files?.image?.[0];

    if (!chefAvatarFile || !imageFile) {
      return res.status(400).json({ message: 'Chef avatar and cover image are required.' });
    }

    // ✅ Capture local paths before uploading
    const chefAvatarPath = chefAvatarFile.path;
    const imagePath = imageFile.path;

    // ✅ Upload to Cloudinary
    const chefAvatarUpload = await cloudinary.uploader.upload(chefAvatarPath, {
      folder: 'courses/avatars',
    });
    const imageUpload = await cloudinary.uploader.upload(imagePath, {
      folder: 'courses/images',
    });

    // ✅ Delete only local temp files
    try {
      if (fs.existsSync(chefAvatarPath)) fs.unlinkSync(chefAvatarPath);
      if (fs.existsSync(imagePath)) fs.unlinkSync(imagePath);
    } catch (cleanupErr) {
      console.warn('⚠️ Warning while deleting local files:', cleanupErr.message);
    }

    // ✅ Generate split video lesson URLs using Cloudinary's `so_` and `eo_`
    const episodes = Array.from({ length: episodeCount }, (_, i) => {
      const start = i * lessonDuration;
      const end = Math.min((i + 1) * lessonDuration, fullDuration);

      const trimmedUrl = videoUrl.replace(
        '/upload/',
        `/upload/so_${start},eo_${end}/`
      );

      return {
        title: `Lesson ${i + 1}`,
        videoUrl: trimmedUrl,
        startTime: start,
        endTime: end,
        duration: (end - start) / 60,
        sourceType: 'cloudinary',
      };
    });

    // ✅ Create course
    const course = await Course.create({
      title,
      description,
      chefName,
      chefAvatar: chefAvatarUpload.secure_url,
      image: imageUpload.secure_url,
      episodes,
    });

    res.status(201).json(course);
  } catch (err) {
    console.error('❌ Error creating course from video:', err);
    res.status(500).json({
      message: 'Failed to create course',
      error: err.message,
    });
  }
};


// Get all courses
exports.getAllCourses = async (req, res) => {
  try {
    const courses = await Course.find().sort({ createdAt: -1 });
    res.status(200).json(courses);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch courses', error: err.message });
  }
};

// Rate a course
exports.rateCourse = async (req, res) => {
  try {
    const courseId = req.params.id;
    const { rating } = req.body;

    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({ message: 'Rating must be between 1 and 5' });
    }

    const course = await Course.findById(courseId);
    if (!course) return res.status(404).json({ message: 'Course not found' });

    course.ratings.push(rating);
    await course.save();

    res.status(200).json({ message: 'Rating submitted', ratings: course.ratings });
  } catch (err) {
    res.status(500).json({ message: 'Failed to rate course', error: err.message });
  }
};

const path = require('path');

exports.uploadVideo = async (req, res) => {
  try {
    if (!req.file || !req.file.path) {
      return res.status(400).json({ message: 'No video file found' });
    }

    const filePath = path.resolve(req.file.path); // ✅ Ensure it's absolute
    console.log('📦 Uploading file:', filePath);

    const result = await new Promise((resolve, reject) => {
      cloudinary.uploader.upload_large(
        filePath,
        {
          resource_type: 'video',
          chunk_size: 6 * 1024 * 1024, // 6 MB
          folder: 'courses',
          use_filename: true,
          unique_filename: false,
        },
        (error, result) => {
          if (error) return reject(error);
          resolve(result);
        }
      );
    });

    console.log('✅ Upload success:', result);

    if (!result || !result.secure_url) {
      return res.status(500).json({ message: 'Upload failed', error: 'No secure_url returned' });
    }

    // Delete local file
    fs.unlinkSync(filePath);

    return res.status(200).json({
      message: 'Video uploaded to Cloudinary',
      url: result.secure_url,
      public_id: result.public_id,
    });
  } catch (err) {
    console.error('❌ Upload error:', err);
    return res.status(500).json({
      message: 'Upload failed',
      error: err.message || 'Unknown error',
    });
  }
};

function generateLessons(videoUrl, fullDuration, lessonLength = 120) {
  const lessons = [];
  let start = 0;
  let index = 1;

  while (start < fullDuration) {
    const end = Math.min(start + lessonLength, fullDuration);
    const trimmedUrl = videoUrl.replace('/upload/', `/upload/so_${start},eo_${end}/`);
    lessons.push({
      title: `Lesson ${index}`,
      videoUrl: trimmedUrl,
      duration: (end - start) / 60
    });
    start = end;
    index++;
  }

  return lessons;
}

// Delete a course
exports.deleteCourse = async (req, res) => {
  try {
    const { id } = req.params;

    const course = await Course.findById(id);
    if (!course) {
      return res.status(404).json({ message: 'Course not found' });
    }

    // Optional: You could also delete associated videos/images from Cloudinary here
    // by using `cloudinary.uploader.destroy(public_id)` if you store `public_id`s

    await course.deleteOne();

    res.status(200).json({ message: 'Course deleted successfully' });
  } catch (err) {
    console.error('❌ Failed to delete course:', err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};


