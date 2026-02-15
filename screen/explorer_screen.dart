import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:stack_appodeal_flutter/stack_appodeal_flutter.dart';
import 'package:cuecue/view/favorite_search_explorer_player_view.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExplorerView extends StatefulWidget {
  const ExplorerView({super.key});

  @override
  State<ExplorerView> createState() => _ExplorerViewState();
}

class _ExplorerViewState extends State<ExplorerView> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _allVideos = [];
  List<dynamic> _displayVideos = [];
  List<String> _dynamicCategories = ["All"];
  List<String> _favoriteIds = [];
  bool _isLoading = true;
  String _selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadFavorites();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // --- PERSISTENCIA DE FAVORITOS ---
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteIds = prefs.getStringList('favorite_videos') ?? [];
    });
  }

  Future<void> _toggleFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
      } else {
        _favoriteIds.add(id);
      }
    });
    await prefs.setStringList('favorite_videos', _favoriteIds);
  }

  // --- LÓGICA DE EPISODIOS BASADA EN DURACIÓN ---
  // Dailymotion entrega 'duration' en segundos.
  // Dividimos segundos / 60 para tener minutos, y luego / 2 para los episodios.
  String _calculateEpisodesFromDuration(dynamic duration) {
    if (duration == null) return "1";
    int totalSeconds = int.tryParse(duration.toString()) ?? 0;
    if (totalSeconds == 0) return "1";

    double minutes = totalSeconds / 60;
    int episodes = (minutes / 2).ceil(); // .ceil() para redondear hacia arriba

    return episodes.toString();
  }

  Future<void> _loadInitialData() async {
    final List<String> channels = [
      'CinePulseChannel',
      'combofilm',
      'LCHDORAMAS',
      'NovelasHDTM',
    ];
    try {
      final requests = channels.map(
        (channel) => http.get(
          Uri.parse(
            'https://api.dailymotion.com/user/$channel/videos?fields=id,title,thumbnail_720_url,duration,views_total&limit=50',
          ),
        ),
      );

      final responses = await Future.wait(requests);
      List<dynamic> allFetchedVideos = [];
      Set<String> extractedWords = {"All"};

      for (var response in responses) {
        if (response.statusCode == 200) {
          final List<dynamic> fetchedVideos = json.decode(
            response.body,
          )['list'];
          allFetchedVideos.addAll(fetchedVideos);
          for (var video in fetchedVideos) {
            String title = video['title'].toString();
            List<String> words = title
                .split(' ')
                .where((w) => w.length > 5)
                .map((w) => w.replaceAll(RegExp(r'[^\w\s]'), ''))
                .toList();
            if (words.isNotEmpty) extractedWords.add(words[0]);
          }
        }
      }

      if (mounted) {
        setState(() {
          allFetchedVideos.shuffle();
          _allVideos = allFetchedVideos;
          _displayVideos = allFetchedVideos;
          _dynamicCategories = extractedWords.take(12).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _displayVideos = category == "All"
          ? _allVideos
          : _allVideos
                .where(
                  (v) => v['title'].toString().toLowerCase().contains(
                    category.toLowerCase(),
                  ),
                )
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackgroundGlow(),
          _isLoading
              ? _buildShimmerLoadingLayout()
              : CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAnimatedHero(),
                    _buildSectionHeader("CATEGORÍAS"),
                    SliverToBoxAdapter(child: _buildDynamicCategoryBar()),
                    _buildSectionHeader("CONTENIDO PREMIUM"),
                    _buildMainGridWithAds(),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
        ],
      ),
    );
  }

  // --- COMPONENTES UI ---

  Widget _buildBackgroundGlow() {
    return Positioned(
      top: -100,
      right: -50,
      child: Container(
        width: 400,
        height: 400,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.redAccent.withValues(alpha: 0.04),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.08),
              blurRadius: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, top: 30, bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white24,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHero() {
    if (_allVideos.isEmpty) return const SliverToBoxAdapter();
    final featured = _allVideos[0];
    final isFav = _favoriteIds.contains(featured['id']);

    return SliverToBoxAdapter(
      child: Stack(
        children: [
          Container(
            height: 550,
            foregroundDecoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black,
                ],
              ),
            ),
            child: Image.network(
              featured['thumbnail_720_url'],
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "TOP TENDENCIA",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  featured['title'].toString().toUpperCase(),
                  maxLines: 2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildActionBtn(
                      Icons.play_arrow_rounded,
                      "REPRODUCIR",
                      Colors.white,
                      Colors.black,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FavoriteSearchPlayerView(videoData: featured),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    // BOTÓN DE FAVORITOS EN EL HERO
                    _buildActionBtn(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      isFav ? "GUARDADO" : "AÑADIR",
                      Colors.white.withValues(alpha: 0.1),
                      isFav ? Colors.redAccent : Colors.white,
                      () => _toggleFavorite(featured['id']),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(
    IconData icon,
    String label,
    Color bg,
    Color text,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: bg,
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: text, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicCategoryBar() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _dynamicCategories.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final cat = _dynamicCategories[index];
          bool sel = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => _filterByCategory(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(
                  color: sel
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    cat.toUpperCase(),
                    style: TextStyle(
                      color: sel ? Colors.black : Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainGridWithAds() {
    List<dynamic> items = [];
    for (int i = 0; i < _displayVideos.length; i++) {
      items.add(_displayVideos[i]);
      if ((i + 1) % 6 == 0) items.add("AD");
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 25,
          crossAxisSpacing: 15,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          if (items[index] == "AD") return _buildMrecAdItem();
          return _buildPosterCard(items[index]);
        }, childCount: items.length),
      ),
    );
  }

  Widget _buildPosterCard(dynamic video) {
    bool isFav = _favoriteIds.contains(video['id']);
    // CÁLCULO DE EPISODIOS BASADO EN DURACIÓN DIVIDIDO 2 MINUTOS
    String epCount = _calculateEpisodesFromDuration(video['duration']);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FavoriteSearchPlayerView(videoData: video),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      video['thumbnail_720_url'],
                      fit: BoxFit.cover,
                    ),
                  ),
                  // BADGE DE EPISODIOS
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "$epCount EPISODIOS",
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // CORAZÓN DE FAVORITO FLOTANTE
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(video['id']),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.white.withValues(alpha: 0.1),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.redAccent : Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            video['title'],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoadingLayout() {
    return Shimmer.fromColors(
      baseColor: Colors.white10,
      highlightColor: Colors.white24,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(height: 550, color: Colors.black),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 15,
                childAspectRatio: 0.7,
                children: List.generate(
                  4,
                  (i) => Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMrecAdItem() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Center(
        child: AppodealBanner(
          adSize: AppodealBannerSize.MEDIUM_RECTANGLE,
          placement: "default",
        ),
      ),
    );
  }
}
