import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:cuecue/widget/build_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stack_appodeal_flutter/stack_appodeal_flutter.dart';
import 'dart:ui';
import 'dart:async'; // Necesario para el Timer

class UIOverlayWidget extends StatefulWidget {
  final VideoPlayerController? playerController;
  final int currentEp;
  final String title;
  final String videoId;
  final bool
  showBanner; // Mantenemos el flag por si el padre quiere apagarlo fijo

  const UIOverlayWidget({
    super.key,
    required this.playerController,
    required this.currentEp,
    required this.title,
    required this.videoId,
    this.showBanner = true,
  });

  @override
  State<UIOverlayWidget> createState() => _UIOverlayWidgetState();
}

class _UIOverlayWidgetState extends State<UIOverlayWidget> {
  bool isFavorite = false;

  // Lógica para el banner intermitente
  bool _isBannerVisible = true;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();

    // Si el padre permite banners, iniciamos el ciclo de 10 segundos
    if (widget.showBanner) {
      _startBannerCycle();
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel(); // IMPORTANTE: Limpiar el timer al cerrar
    super.dispose();
  }

  void _startBannerCycle() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _isBannerVisible = !_isBannerVisible;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant UIOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _checkIfFavorite();
    }
  }

  Future<void> _checkIfFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favorites = prefs.getStringList('favorite_videos') ?? [];
    if (mounted) {
      setState(() => isFavorite = favorites.contains(widget.videoId));
    }
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favorite_videos') ?? [];

    setState(() {
      if (isFavorite) {
        favorites.remove(widget.videoId);
        isFavorite = false;
      } else {
        favorites.add(widget.videoId);
        isFavorite = true;
      }
    });

    await prefs.setStringList('favorite_videos', favorites);
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.5),
              Colors.black.withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        BuildSliderWidget(
                          playerController: widget.playerController,
                          currentEp: widget.currentEp,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  _buildGlassFavoriteButton(),
                ],
              ),

              // Banner con visibilidad dinámica y animación suave
              AnimatedSize(
                duration: const Duration(milliseconds: 500),
                child: Visibility(
                  visible: widget.showBanner && _isBannerVisible,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      AppodealBanner(
                        adSize: AppodealBannerSize.BANNER,
                        placement: "default",
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassFavoriteButton() {
    return GestureDetector(
      onTap: _toggleFavorite,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isFavorite
                  ? Colors.redAccent.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isFavorite
                    ? Colors.redAccent.withOpacity(0.5)
                    : Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.redAccent : Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
