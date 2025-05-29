import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' as ui;
import 'dart:html' as html;

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({super.key, required this.videoUrl});

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
      if (kIsWeb) {
        print('❌ Video playback not supported on web by default.');
        setState(() => _hasError = true);
        return;
      }

      // ✅ Optimize Cloudinary URL if applicable
      final optimizedUrl =
          widget.videoUrl.contains('/upload/')
              ? widget.videoUrl.replaceFirst(
                '/upload/',
                '/upload/f_auto,q_auto/',
              )
              : widget.videoUrl;

      _videoPlayerController = VideoPlayerController.network(optimizedUrl);
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio:
            _videoPlayerController.value.aspectRatio > 0
                ? _videoPlayerController.value.aspectRatio
                : 16 / 9,
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
    if (kIsWeb) {
      // 🛠 Register factory safely
      final viewId = 'videoElement-${DateTime.now().millisecondsSinceEpoch}';

      // ✅ Only access `platformViewRegistry` if web
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(viewId, (int _) {
        final video =
            html.VideoElement()
              ..src = widget.videoUrl
              ..autoplay = true
              ..controls = true
              ..style.border = 'none'
              ..style.width = '100%'
              ..style.height = '100%';
        return video;
      });

      return Scaffold(
        appBar: AppBar(title: const Text("Watch Episode")),
        body: HtmlElementView(viewType: viewId),
      );
    }

    // The existing native Android/iOS code...
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Watch Episode"),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child:
            _hasError
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 50,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '❌ Failed to load video',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _initializePlayer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                )
                : (_chewieController != null &&
                    _chewieController!
                        .videoPlayerController
                        .value
                        .isInitialized)
                ? Chewie(controller: _chewieController!)
                : const CircularProgressIndicator(color: Colors.teal),
      ),
    );
  }
}
