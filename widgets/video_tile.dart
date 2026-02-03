import 'package:cuecue/models/video_model.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoItem extends StatefulWidget {
  final VideoModel video;
  const VideoItem({super.key, required this.video});

  @override
  State<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.video.streamUrl))
          ..initialize().then((_) {
            if (mounted) {
              setState(() {
                _isInitialized = true;
                _controller.setLooping(true);
                _controller.play();
              });
            }
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _isInitialized
            ? Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              )
            : const Center(child: CircularProgressIndicator(color: Colors.red)),

        // Información y Botón de Detalles
        Positioned(
          bottom: 40,
          left: 20,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.video.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "@DailymotionUser",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),

        // BOTÓN DE IR A DETALLES (Ruta Directa)
        Positioned(
          right: 20,
          bottom: 50,
          child: FloatingActionButton(
            backgroundColor: Colors.white24,
            child: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/details', arguments: widget.video);
            },
          ),
        ),
      ],
    );
  }
}
