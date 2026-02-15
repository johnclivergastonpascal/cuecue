import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';

class VideoLogicHelper {
  static void handleVideoListener({
    required VideoPlayerController? playerController,
    required PageController episodeController,
    required int currentEp,
    required int videoDuration,
  }) {
    if (playerController == null || !playerController.value.isInitialized)
      return;
    final int currentSeconds = playerController.value.position.inSeconds;
    final int epEndTime = (currentEp + 1) * 120;

    if (playerController.value.isPlaying && currentSeconds >= epEndTime) {
      final int totalSegments = (videoDuration / 120).ceil();
      if (currentEp < totalSegments - 1) {
        if (!episodeController.position.isScrollingNotifier.value) {
          episodeController.nextPage(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }
    }
  }

  static bool togglePlay(VideoPlayerController? playerController) {
    if (playerController == null || !playerController.value.isInitialized)
      return false;
    playerController.value.isPlaying
        ? playerController.pause()
        : playerController.play();
    return true;
  }

  // --- NUEVO MÉTODOS PARA FAVORITOS ---
  static Future<bool> toggleFavorite(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favorite_videos') ?? [];

    if (favorites.contains(videoId)) {
      // Si ya existe, podrías decidir no hacer nada en doble clic
      // o quitarlo. Normalmente en doble clic solo se agrega.
      return true;
    } else {
      favorites.add(videoId);
      await prefs.setStringList('favorite_videos', favorites);
      return true; // Retorna true para activar la animación
    }
  }
}
