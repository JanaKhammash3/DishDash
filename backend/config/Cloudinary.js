const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');

// ✅ Configure Cloudinary using environment variables
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME || 'your_cloud_name',
  api_key: process.env.CLOUDINARY_API_KEY || 'your_api_key',
  api_secret: process.env.CLOUDINARY_API_SECRET || 'your_api_secret',
});

// ✅ Define storage strategy for multer
const storage = new CloudinaryStorage({
  cloudinary,
  params: async (req, file) => ({
    folder: 'courses',
    resource_type: 'video', // 🔁 Better to set this to 'video' explicitly for large files
    format: 'mp4',
    public_id: `course-${Date.now()}-${file.originalname.split('.')[0]}`,
  }),
});

module.exports = {
  cloudinary,
  storage,
};
