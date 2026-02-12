import 'dart:convert';
import 'package:cuecue/widget/tiktok_loader.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stack_appodeal_flutter/stack_appodeal_flutter.dart'; // Importar Appodeal
import 'package:cuecue/view/favorite_search_explorer_player_view.dart';

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

  bool _isLoading = true;
  String _selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.dailymotion.com/user/CinePulseChannel/videos?fields=id,title,thumbnail_720_url,duration,views_total&limit=100',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> fetchedVideos = json.decode(response.body)['list'];
        Set<String> extractedWords = {"All"};
        for (var video in fetchedVideos) {
          String title = video['title'].toString();
          List<String> words = title
              .split(' ')
              .where((w) => w.length > 5)
              .map((w) => w.replaceAll(RegExp(r'[^\w\s]'), ''))
              .toList();

          if (words.isNotEmpty) {
            extractedWords.add(words[0]);
          }
        }

        setState(() {
          _allVideos = fetchedVideos;
          _displayVideos = fetchedVideos;
          _dynamicCategories = extractedWords.take(10).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == "All") {
        _displayVideos = _allVideos;
      } else {
        _displayVideos = _allVideos
            .where(
              (v) => v['title'].toString().toLowerCase().contains(
                category.toLowerCase(),
              ),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: _isLoading
          ? const Center(child: TikTokLoader(size: 25))
          : CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAnimatedHero(),
                SliverToBoxAdapter(child: _buildDynamicCategoryBar()),
                _buildMainGridWithAds(), // NUEVA LÓGICA AQUÍ
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }

  // --- LÓGICA DE GRID CON MREC ---
  Widget _buildMainGridWithAds() {
    List<Widget> gridItems = [];

    for (int i = 0; i < _displayVideos.length; i++) {
      // Añadir el video actual
      gridItems.add(_buildPosterCard(_displayVideos[i]));

      // Cada 5 videos (índice 4, 9, 14...), insertamos un bloque de anuncio
      // Usamos i + 1 porque el índice empieza en 0
      if ((i + 1) % 5 == 0) {
        gridItems.add(_buildMrecAdItem());
      }
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 25,
          crossAxisSpacing: 15,
          childAspectRatio: 0.7,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => gridItems[index],
          childCount: gridItems.length,
        ),
      ),
    );
  }

  // Widget del Anuncio MREC diseñado para encajar en el Grid
  Widget _buildMrecAdItem() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              "ANUNCIO",
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ),
          Expanded(
            child: AppodealBanner(
              adSize: AppodealBannerSize.MEDIUM_RECTANGLE,
              placement: "default",
            ),
          ),
        ],
      ),
    );
  }

  // --- RESTO DE TUS WIDGETS ---

  Widget _buildAnimatedHero() {
    if (_allVideos.isEmpty) return const SliverToBoxAdapter();
    final featuredVideo = _allVideos[0];
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          Container(
            height: 500,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(featuredVideo['thumbnail_720_url']),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            height: 501,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87, Color(0xFF050505)],
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "DESTACADO DE HOY",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  featuredVideo['title'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _premiumButton(
                      Icons.play_arrow,
                      "PLAY",
                      Colors.white,
                      Colors.black,
                      featuredVideo,
                    ),
                    const SizedBox(width: 12),
                    _premiumButton(
                      Icons.info_outline,
                      "INFO",
                      Colors.white.withOpacity(0.2),
                      Colors.white,
                      featuredVideo,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumButton(
    IconData icon,
    String label,
    Color bg,
    Color text,
    dynamic video,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FavoriteSearchPlayerView(videoData: video),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: text, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: text,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicCategoryBar() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 15),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _dynamicCategories.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final cat = _dynamicCategories[index];
          bool isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (val) => _filterByCategory(cat),
              selectedColor: Colors.cyanAccent,
              backgroundColor: Colors.white.withOpacity(0.05),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
              ),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPosterCard(dynamic video) {
    int durationMinutes = (video['duration'] / 60).round();
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
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FadeInImage.assetNetwork(
                    placeholder:
                        'assets/placeholder.png', // Asegúrate de tener un asset o usa Container
                    image: video['thumbnail_720_url'],
                    fit: BoxFit.cover,
                    imageErrorBuilder: (context, error, stackTrace) =>
                        Container(color: Colors.grey[900]),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.cyanAccent,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        "$durationMinutes MIN",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
