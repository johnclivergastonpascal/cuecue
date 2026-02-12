import 'dart:convert';
import 'package:cuecue/view/favorite_search_explorer_player_view.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  // LÓGICA DE BÚSQUEDA PROFUNDA
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchResults = []; // Limpiar resultados previos
    });

    String searchQuery = query.toLowerCase();
    int page = 1;
    bool hasMore = true;
    List<dynamic> collectedVideos = [];

    try {
      // Bucle "Deep Search": Recorre páginas hasta encontrar contenido o llegar al fin
      while (hasMore && collectedVideos.length < 20) {
        final response = await http.get(
          Uri.parse(
            'https://api.dailymotion.com/user/CinePulseChannel/videos?fields=id,title,thumbnail_720_url,duration&limit=100&page=$page',
          ),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          List<dynamic> fetchedList = data['list'];

          if (fetchedList.isEmpty) {
            hasMore = false; // Ya no hay más videos en el canal
          } else {
            // Filtramos localmente para asegurar que la palabra esté en el título
            var matches = fetchedList.where((video) {
              String title = video['title'].toString().toLowerCase();
              return title.contains(searchQuery);
            }).toList();

            collectedVideos.addAll(matches);

            // Si la API nos dio menos de 100, es la última página
            if (fetchedList.length < 100) hasMore = false;
          }
          page++;

          // Seguridad: Si pasamos de la página 10 y no hay nada, paramos para no bloquear la app
          if (page > 10 && collectedVideos.isEmpty) hasMore = false;
        } else {
          hasMore = false;
        }
      }

      if (mounted) {
        setState(() {
          _searchResults = collectedVideos;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error en Deep Search: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.only(top: 50),
      child: Column(
        children: [
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
    );
  }

  // --- COMPONENTES DE LA UI ---

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        onSubmitted: _performSearch,
        decoration: InputDecoration(
          hintText: "Deep Search ...",
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: const Icon(Icons.manage_search, color: Colors.cyanAccent),
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, color: Colors.white38),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchResults = []);
            },
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
          const CircularProgressIndicator(color: Colors.cyanAccent),
          const SizedBox(height: 20),
          Text(
            "Escaneando todo el canal...",
            style: TextStyle(color: Colors.cyanAccent.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 16 / 11,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) => _buildVideoCard(_searchResults[index]),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off, size: 80, color: Colors.grey[800]),
        const SizedBox(height: 10),
        const Text(
          "No se encontró la palabra exacta",
          style: TextStyle(color: Colors.white38, fontSize: 16),
        ),
      ],
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              video['thumbnail_720_url'] ?? '',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: Colors.grey[900]),
            ),
            _buildCardOverlay(video['title']),
          ],
        ),
      ),
    );
  }

  Widget _buildCardOverlay(String title) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
        ),
      ),
      padding: const EdgeInsets.all(8),
      alignment: Alignment.bottomLeft,
      child: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
