import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:cuecue/widget/build_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stack_appodeal_flutter/stack_appodeal_flutter.dart'; // Importante
import 'dart:ui';

class UIOverlayWidget extends StatefulWidget {
  final VideoPlayerController? playerController;
  final int currentEp;
  final String title;
  final String videoId;

  const UIOverlayWidget({
    super.key,
    required this.playerController,
    required this.currentEp,
    required this.title,
    required this.videoId,
  });

  @override
  State<UIOverlayWidget> createState() => _UIOverlayWidgetState();
}

class _UIOverlayWidgetState extends State<UIOverlayWidget> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  @override
  void didUpdateWidget(covariant UIOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkIfFavorite();
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
              // --- CONTROLES EXISTENTES ---
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

              // --- ESPACIO Y ANUNCIO ---
              const SizedBox(height: 10),

              // Banner de Appodeal
              AppodealBanner(
                adSize: AppodealBannerSize.BANNER,
                placement: "default",
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
