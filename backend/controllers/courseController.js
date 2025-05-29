const Course = require('../models/Course');
const { cloudinary } = require('../config/Cloudinary'); // OR: require('cloudinary').v2
const fs = require('fs');

// Create a new course
exports.createFromSingleVideo = async (req, res) => {
  try {
    const {
      title,
      description,
      chefName,
      chefAvatar,
      image,
      videoUrl,
      fullDuration,
    } = req.body;

    const lessonDuration = 120; // 2 minutes (in seconds)
    const episodeCount = Math.ceil(fullDuration / lessonDuration);

    const baseUrlParts = videoUrl.split('/upload/');
    if (baseUrlParts.length !== 2) {
      return res.status(400).json({ message: 'Invalid Cloudinary URL format' });
    }

    const [beforeUpload, afterUpload] = baseUrlParts;

    const episodes = Array.from({ length: episodeCount }, (_, i) => {
      const start = i * lessonDuration;
      const end = Math.min((i + 1) * lessonDuration, fullDuration);

      // Inject Cloudinary trimming transformation
      const trimmedUrl = `${beforeUpload}/upload/so_${start},eo_${end}/${afterUpload}`;

      return {
        title: `Lesson ${i + 1}`,
        videoUrl: trimmedUrl,
        duration: (end - start) / 60,
      };
    });

    const course = await Course.create({
      title,
      description,
      chefName,
      chefAvatar,
      image,
      episodes,
    });

    res.status(201).json(course);
  } catch (err) {
    console.error('❌ Error creating course from video:', err);
    res.status(500).json({ message: 'Server error' });
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


exports.createFromSingleVideo = async (req, res) => {
  try {
    const {
      title,
      description,
      chefName,
      chefAvatar,
      image,
      videoUrl,
      fullDuration,
    } = req.body;

    const lessonDuration = 120; // 2 minutes
    const episodeCount = Math.ceil(fullDuration / lessonDuration);

    const episodes = Array.from({ length: episodeCount }, (_, i) => {
      const start = i * lessonDuration;
      const end = Math.min((i + 1) * lessonDuration, fullDuration);
      return {
        title: `Lesson ${i + 1}`,
        videoUrl,
        startTime: start,
        endTime: end,
        duration: (end - start) / 60,
      };
    });

    const course = await Course.create({
      title,
      description,
      chefName,
      chefAvatar,
      image,
      episodes,
    });

    res.status(201).json(course);
  } catch (err) {
    console.error('❌ Error creating course from video:', err);
    res.status(500).json({ message: 'Server error' });
  }
};
