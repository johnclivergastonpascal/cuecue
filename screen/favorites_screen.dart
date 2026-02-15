import 'dart:ui';
import 'package:cuecue/widget/favorite_video_card.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class FavoritesScreen extends StatefulWidget {
  final Function(String) onPlayVideo;
  final bool isActive;

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
    if (widget.isActive && !oldWidget.isActive) {
      _loadFavorites();
    }
  }

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
      body: Stack(
        children: [
          // 1. Resplandor de fondo (estilo Premium)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withValues(alpha: 0.05),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    blurRadius: 150,
                  ),
                ],
              ),
            ),
          ),

          // 2. Contenido principal
          Column(
            children: [
              _buildCustomAppBar(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingIndicator()
                    : _favoriteIds.isEmpty
                    ? _buildEmptyState()
                    : _buildAnimatedList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // AppBar con efecto Glassmorphism
  Widget _buildCustomAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.only(top: 50, bottom: 20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            border: const Border(
              bottom: BorderSide(color: Colors.white10, width: 0.5),
            ),
          ),
          child: const Center(
            child: Text(
              "MIS FAVORITOS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w200, // Estilo minimalista
                letterSpacing: 4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.redAccent, strokeWidth: 2),
    );
  }

  Widget _buildAnimatedList() {
    return RefreshIndicator(
      backgroundColor: Colors.grey[900],
      color: Colors.redAccent,
      onRefresh: _loadFavorites,
      child: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          itemCount: _favoriteIds.length,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 600),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: FavoriteVideoCard(
                      key: ValueKey(_favoriteIds[index]),
                      videoId: _favoriteIds[index],
                      onRemove: () => _loadFavorites(),
                    ),
                  ),
                ),
              ),
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
        children: [
          Icon(
            Icons.favorite_outline_rounded,
            size: 80,
            color: Colors.redAccent.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 20),
          const Text(
            "TU COLECCIÓN ESTÁ VACÍA",
            style: TextStyle(
              color: Colors.white24,
              letterSpacing: 2,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
