import 'dart:convert';
import 'package:cuecue/widget/build_ui_overlay.dart';
import 'package:cuecue/widget/fade_in_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class VideoPlayerItem extends StatefulWidget {
  final String videoId, title;
  final Map<String, dynamic>? thumbnails; // Recibe los thumbnails precargados
  final Function(int) onTimeUpdate;
  final bool shouldPlay;
  final Duration initialPosition;

  const VideoPlayerItem({
    super.key,
    required this.videoId,
    required this.title,
    this.thumbnails,
    required this.onTimeUpdate,
    required this.shouldPlay,
    this.initialPosition = Duration.zero,
  });

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  VideoPlayerController? _controller;
  bool isInitialized = false;
  bool showIcon = false;
  bool _showFullVideoButton = false; // Nueva variable de estado

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(VideoPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (widget.shouldPlay && !_controller!.value.isPlaying) {
      _controller?.play();
    } else if (!widget.shouldPlay && _controller!.value.isPlaying) {
      _controller?.pause();
    }

    if (widget.initialPosition != oldWidget.initialPosition &&
        widget.shouldPlay) {
      _controller?.seekTo(widget.initialPosition);
    }
  }

  Future<void> _initializeVideo() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://www.dailymotion.com/player/metadata/video/${widget.videoId}',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final videoUrl = data['qualities']['auto'][0]['url'];

        _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
        await _controller!.initialize();

        if (mounted) {
          if (widget.initialPosition > Duration.zero) {
            await _controller!.seekTo(widget.initialPosition);
          }

          setState(() => isInitialized = true);

          if (widget.shouldPlay) {
            _controller?.play();
          }

          _controller?.setLooping(false);
          _controller?.addListener(_videoListener);
        }
      }
    } catch (e) {
      debugPrint("Error al inicializar VideoPlayerItem: $e");
    }
  }

  void _videoListener() {
    if (_controller != null && _controller!.value.isInitialized) {
      final int currentSeconds = _controller!.value.position.inSeconds;

      // Notificamos el tiempo al padre
      widget.onTimeUpdate(currentSeconds);

      // LÓGICA DEL BOTÓN: Aparece después de los 10 segundos
      // y desaparece si el usuario vuelve al inicio
      if (currentSeconds >= 10 && !_showFullVideoButton) {
        setState(() => _showFullVideoButton = true);
      } else if (currentSeconds < 10 && _showFullVideoButton) {
        setState(() => _showFullVideoButton = false);
      }
    }
  }

  void _togglePlay() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
      showIcon = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => showIcon = false);
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos la URL de la imagen de alta calidad
    final String? thumbUrl =
        widget.thumbnails?['1080'] ?? widget.thumbnails?['720'];

    return GestureDetector(
      onTap: _togglePlay,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. EL THUMBNAIL (Se muestra siempre de fondo mientras carga el video)
            if (thumbUrl != null)
              SizedBox.expand(
                child: Image.network(
                  thumbUrl,
                  // precacheImage en el feed hará que esto aparezca al instante
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) => child,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: Colors.black),
                ),
              ),

            // 2. BOTÓN "VER COMPLETO" (Nuevo Widget)
            // 2. BOTÓN "VER COMPLETO"
            if (_showFullVideoButton)
              Positioned(
                bottom:
                    130, // Lo bajamos un poco para que esté cerca del borde inferior
                left: 0,
                right: 0,
                child: Center(
                  // Esto lo centra horizontalmente
                  child: GestureDetector(
                    onTap:
                        () {}, // ESTO ES CLAVE: Detiene el tap para que el video NO se pause
                    child: FadeInButton(
                      onPressed: () async {
                        // 1. Girar primero
                        await SystemChrome.setPreferredOrientations([
                          DeviceOrientation.landscapeLeft,
                          DeviceOrientation.landscapeRight,
                        ]);

                        await SystemChrome.setEnabledSystemUIMode(
                          SystemUiMode.immersiveSticky,
                        );

                        // 2. Esperar un poquito a que el sensor reaccione
                        await Future.delayed(const Duration(milliseconds: 200));

                        // 3. Cambiar de página
                        widget.onTimeUpdate(120);
                      },
                    ),
                  ),
                ),
              ),
            // 3. EL VIDEO (Se dibuja encima cuando está listo)
            if (isInitialized && _controller != null)
              SizedBox.expand(
                child: FittedBox(
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              ),

            // 3. ICONO PLAY/PAUSE
            if (showIcon)
              Icon(
                _controller!.value.isPlaying ? Icons.play_arrow : Icons.pause,
                size: 80,
                color: Colors.white.withValues(alpha: 0.5),
              ),

            // 4. OVERLAY (Se muestra siempre para que el usuario pueda ver el título)
            UIOverlayWidget(
              playerController: _controller,
              currentEp: (widget.initialPosition.inSeconds ~/ 120) + 1,
              title: widget.title,
              videoId: widget.videoId,
              showBanner: false,
            ),
          ],
        ),
      ),
    );
  }
}
