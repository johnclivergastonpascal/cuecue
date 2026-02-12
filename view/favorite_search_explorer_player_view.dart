import 'package:cuecue/view/video_segments_view.dart';
import 'package:flutter/material.dart';

class FavoriteSearchPlayerView extends StatefulWidget {
  final Map<String, dynamic> videoData;

  const FavoriteSearchPlayerView({super.key, required this.videoData});

  @override
  State<FavoriteSearchPlayerView> createState() =>
      _FavoriteSearchPlayerViewState();
}

class _FavoriteSearchPlayerViewState extends State<FavoriteSearchPlayerView> {
  int _currentEp = 1;
  VoidCallback? _openModal;

  // Variables para el control de pausa/play
  bool _isPlaying = true;
  bool _showIcon = false;

  void _handleTogglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      _showIcon = true;
    });

    // Escondemos el icono central después de medio segundo
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _showIcon = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. DETECTOR DE GESTOS PARA PAUSA/PLAY
          GestureDetector(
            onTap: _handleTogglePlay,
            child: VideoSegmentsView(
              videoData: widget.videoData,
              isVisible: _isPlaying, // Usamos el estado para pausar/reproducir
              initialPosition: Duration.zero,
              onTimeUpdate: (pos) {},
              onEpChanged: (ep, openModalFunc) {
                setState(() {
                  _currentEp = ep;
                  _openModal = openModalFunc;
                });
              },
            ),
          ),

          // 2. ICONO DE FEEDBACK CENTRAL (Pausa/Play)
          if (_showIcon)
            IgnorePointer(
              // Para que el icono no bloquee los toques
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    size: 80,
                    color: Colors.cyanAccent,
                  ),
                ),
              ),
            ),

          // 3. BOTÓN DE REGRESAR
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 4. INDICADOR DE EPISODIO Y BOTÓN DE MODAL
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.cyanAccent.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    "EPISODIO $_currentEp",
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.grid_view_rounded,
                      color: Colors.black,
                      size: 22,
                    ),
                    onPressed: () => _openModal?.call(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
