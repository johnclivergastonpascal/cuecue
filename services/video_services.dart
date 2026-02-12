import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';

class VideoService {
  /// Obtiene la URL de Dailymotion e inicializa el controlador
  static Future<VideoPlayerController?> initController({
    required String videoId,
    required VoidCallback onVideoListener,
    bool startInEpisodeTwo = false,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.dailymotion.com/player/metadata/video/$videoId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final videoUrl = data['qualities']['auto'][0]['url'];

        final controller = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
        );

        await controller.initialize();
        controller.addListener(onVideoListener);
        controller.setLooping(true);

        // Lógica de salto inicial
        if (startInEpisodeTwo) {
          await controller.seekTo(const Duration(seconds: 120));
        }

        // Ejecutar play con lógica de reintento (autoplay)
        await _handleAutoplay(controller);

        return controller;
      }
    } catch (e) {
      debugPrint("Error VideoService: $e");
    }
    return null;
  }

  static Future<void> _handleAutoplay(VideoPlayerController controller) async {
    await controller.play();
    if (!controller.value.isPlaying) {
      await controller.setVolume(
        0,
      ); // Mute para forzar autoplay si el sistema bloquea
      await controller.play();
    }
  }
}
