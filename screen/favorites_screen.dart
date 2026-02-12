import 'package:cuecue/widget/favorite_video_card.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesScreen extends StatefulWidget {
  final Function(String) onPlayVideo;
  final bool isActive; // <--- Nuevo: Para saber si la pantalla está visible
  const FavoritesScreen({
    super.key,
    required this.onPlayVideo,
    this.isActive = false,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<String> _favoriteIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void didUpdateWidget(covariant FavoritesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si antes no estaba activa y ahora sí, actualizamos la lista
    if (widget.isActive && !oldWidget.isActive) {
      _loadFavorites();
    }
  }

  // Cargamos la lista de IDs desde el caché
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _favoriteIds = prefs.getStringList('favorite_videos') ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Mis Favoritos",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            )
          : _favoriteIds.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadFavorites,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: _favoriteIds.length,
                itemBuilder: (context, index) {
                  return FavoriteVideoCard(
                    key: ValueKey(_favoriteIds[index]),
                    videoId: _favoriteIds[index],
                    onRemove: () => _loadFavorites(),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.favorite_border, size: 80, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            "Tu lista está vacía",
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
