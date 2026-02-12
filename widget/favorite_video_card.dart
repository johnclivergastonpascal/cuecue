import 'dart:convert';

import 'package:cuecue/view/favorite_search_explorer_player_view.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// --- WIDGET DE TARJETA INTELIGENTE ---
class FavoriteVideoCard extends StatefulWidget {
  final String videoId;
  final VoidCallback onRemove;

  const FavoriteVideoCard({
    super.key,
    required this.videoId,
    required this.onRemove,
  });

  @override
  State<FavoriteVideoCard> createState() => _FavoriteVideoCardState();
}

class _FavoriteVideoCardState extends State<FavoriteVideoCard> {
  Map<String, dynamic>? videoData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchVideoMetadata();
  }

  // La misma lógica de metadatos que usas en el reproductor
  Future<void> _fetchVideoMetadata() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://www.dailymotion.com/player/metadata/video/${widget.videoId}',
        ),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            videoData = json.decode(response.body);
            loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error cargando favorito: $e");
    }
  }

  @override
  void didUpdateWidget(covariant FavoriteVideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el videoId cambió, volvemos a cargar la metadata
    if (widget.videoId != oldWidget.videoId) {
      setState(() => loading = true);
      _fetchVideoMetadata();
    }
  }

  Future<void> _deleteFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList('favorite_videos') ?? [];
    favs.remove(widget.videoId);
    await prefs.setStringList('favorite_videos', favs);
    widget.onRemove(); // Notifica al padre para refrescar la lista
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
        ),
      );
    }

    final String title = videoData?['title'] ?? 'Sin título';
    final String thumb =
        videoData?['thumbnails']?['720'] ??
        videoData?['thumbnails']?['480'] ??
        '';
    final int duration = videoData?['duration'] ?? 0;
    final int totalEps = (duration / 120).ceil(); // Lógica de episodios

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            thumb,
            width: 80,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: Colors.grey, width: 80, height: 60),
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "$totalEps Episodios",
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.favorite, color: Colors.redAccent),
          onPressed: _deleteFromPrefs,
        ),
        onTap: () {
          if (videoData != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    FavoriteSearchPlayerView(videoData: videoData!),
              ),
            );
          }
        },
      ),
    );
  }
}
