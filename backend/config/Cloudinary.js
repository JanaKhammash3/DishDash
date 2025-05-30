const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');

// 🔐 Config Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME || 'your_cloud_name',
  api_key: process.env.CLOUDINARY_API_KEY || 'your_api_key',
  api_secret: process.env.CLOUDINARY_API_SECRET || 'your_api_secret',
});

// ✅ Storage for Videos
const videoStorage = new CloudinaryStorage({
  cloudinary,
  params: async (req, file) => ({
    folder: 'courses/videos',
    resource_type: 'video',
    format: 'mp4',
    public_id: `course-${Date.now()}-${file.originalname.split('.')[0]}`,
  }),
});

// ✅ Storage for Images
const imageStorage = new CloudinaryStorage({
  cloudinary,
  params: async (req, file) => ({
    folder: 'courses/images',
    resource_type: 'image',
    public_id: `image-${Date.now()}-${file.originalname.split('.')[0]}`,
  }),
});

module.exports = {
  cloudinary,
  videoStorage,
  imageStorage,
};
