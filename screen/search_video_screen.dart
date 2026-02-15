import 'dart:convert';
import 'dart:ui'; // Necesario para ImageFilter
import 'package:cuecue/view/favorite_search_explorer_player_view.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class SearchVideosView extends StatefulWidget {
  final Function(dynamic) onVideoTap;

  const SearchVideosView({super.key, required this.onVideoTap});

  @override
  State<SearchVideosView> createState() => _SearchVideosViewState();
}

class _SearchVideosViewState extends State<SearchVideosView> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchResults = [];
    });

    final String searchQuery = query.toLowerCase();
    final List<String> channels = [
      'CinePulseChannel',
      'combofilm',
      'LCHDORAMAS',
      'NovelasHDTM',
    ];

    List<dynamic> allCollectedVideos = [];

    try {
      final searchTasks = channels.map((channel) async {
        List<dynamic> channelMatches = [];
        int page = 1;
        bool hasMore = true;

        while (hasMore && channelMatches.length < 15) {
          final response = await http.get(
            Uri.parse(
              'https://api.dailymotion.com/user/$channel/videos?fields=id,title,thumbnail_720_url,duration&limit=100&page=$page',
            ),
          );

          if (response.statusCode == 200) {
            final List<dynamic> fetchedList = json.decode(
              response.body,
            )['list'];
            if (fetchedList.isEmpty) {
              hasMore = false;
            } else {
              var matches = fetchedList.where((video) {
                String title = video['title'].toString().toLowerCase();
                return title.contains(searchQuery);
              }).toList();
              channelMatches.addAll(matches);
              if (fetchedList.length < 100) hasMore = false;
            }
            page++;
            if (page > 10) hasMore = false;
          } else {
            hasMore = false;
          }
        }
        return channelMatches;
      }).toList();

      final resultsPerChannel = await Future.wait(searchTasks);
      for (var list in resultsPerChannel) {
        allCollectedVideos.addAll(list);
      }

      if (mounted) {
        setState(() {
          allCollectedVideos.shuffle();
          _searchResults = allCollectedVideos;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fondo con un ligero resplandor superior
          Positioned(
            top: -100,
            left: MediaQuery.of(context).size.width / 4,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.cyanAccent.withOpacity(0.05),
                boxShadow: [
                  BoxShadow(color: Colors.cyanAccent, blurRadius: 150),
                ],
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 60),
              _buildSearchBar(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingIndicator()
                    : _searchResults.isEmpty
                    ? _buildPlaceholder()
                    : _buildResultsGrid(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10, width: 1),
            ),
            child: TextField(
              controller: _searchController,
              onSubmitted: _performSearch,
              style: const TextStyle(color: Colors.white, letterSpacing: 1),
              decoration: InputDecoration(
                hintText: "Buscar en la red profunda...",
                hintStyle: const TextStyle(
                  color: Colors.white24,
                  fontWeight: FontWeight.w300,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.cyanAccent,
                  size: 28,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white38,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: Colors.cyanAccent,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Rastreando servidores...",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              letterSpacing: 2,
              fontSize: 12,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsGrid() {
    return AnimationLimiter(
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.8, // Ajustado para que el texto respire
        ),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final video = _searchResults[index];
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 500),
            columnCount: 2,
            child: ScaleAnimation(
              scale: 0.9,
              child: FadeInAnimation(child: _buildVideoCard(video)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoCard(dynamic video) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FavoriteSearchPlayerView(videoData: video),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      video['thumbnail_720_url'] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) =>
                          Container(color: Colors.grey[900]),
                    ),
                    // Glassmorphism overlay en la duración (opcional)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          "HD",
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              video['title'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Opacity(
        opacity: 0.4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bubble_chart_outlined,
              size: 100,
              color: Colors.cyanAccent,
            ),
            const SizedBox(height: 20),
            Text(
              "DESCUBRE CONTENIDO",
              style: TextStyle(
                color: Colors.white,
                letterSpacing: 4,
                fontSize: 14,
                fontWeight: FontWeight.w200,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
