const Post = require('../models/Post'); // make sure this exists
exports.getUserLikesCount = async (req, res) => {
  try {
    const posts = await Post.find({ author: req.params.userId });
    const totalLikes = posts.reduce((sum, post) => sum + (post.likes?.length || 0), 0);
    res.json({ totalLikes });
  } catch (err) {
    res.status(500).json({ error: 'Failed to get like count' });
  }
};

