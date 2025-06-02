import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:frontend/colors.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final int startTime;
  final int endTime;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.startTime,
    required this.endTime,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final optimizedUrl =
          widget.videoUrl.contains('/upload/')
              ? widget.videoUrl.replaceFirst(
                '/upload/',
                '/upload/f_auto,q_auto/',
              )
              : widget.videoUrl;

      _videoPlayerController = VideoPlayerController.network(optimizedUrl);
      await _videoPlayerController.initialize();
      await _videoPlayerController.seekTo(Duration(seconds: widget.startTime));

      _videoPlayerController.addListener(() {
        final pos = _videoPlayerController.value.position;
        if (pos.inSeconds >= widget.endTime) {
          _videoPlayerController.pause();
        }
      });

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio:
            _videoPlayerController.value.aspectRatio > 0
                ? _videoPlayerController.value.aspectRatio
                : 16 / 9,
        showControls: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
      );

      setState(() => _hasError = false);
    } catch (e) {
      print('❌ Error initializing video: $e');
      setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("🎥 Watch Episode"),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child:
            _hasError
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 50,
                    ),
                    SizedBox(height: 12),
                    Text(
                      '❌ Failed to load video',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: Icon(Icons.refresh),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _initializePlayer,
                      label: Text("Retry"),
                    ),
                  ],
                )
                : (_chewieController != null &&
                    _chewieController!
                        .videoPlayerController
                        .value
                        .isInitialized)
                ? AspectRatio(
                  aspectRatio: _videoPlayerController.value.aspectRatio,
                  child: Chewie(controller: _chewieController!),
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 12),
                    Text(
                      "Loading video...",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
      ),
    );
  }
}
