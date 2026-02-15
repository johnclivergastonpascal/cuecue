import 'dart:convert';

import 'package:cuecue/screen/favorites_screen.dart';
import 'package:cuecue/screen/explorer_screen.dart';
import 'package:cuecue/screen/search_video_screen.dart';
import 'package:cuecue/view/video_vertical_feed.dart';
import 'package:cuecue/view/video_segments_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// ignore: must_be_immutable
class MainScreen extends StatefulWidget {
  String? initialVideoId;
  MainScreen({super.key, this.initialVideoId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final PageController _forYouHorizontalController = PageController();

  int _selectedIndex = 1;
  int _innerHorizontalIndex = 0;
  dynamic _currentVideoData;
  DateTime? _lastPressedAt;

  int _currentEpFromChild = 1;
  VoidCallback? _openModalFromAppBar;

  // VARIABLE CLAVE: Esta es la "Fuente de verdad" del tiempo del video
  Duration _lastGlobalPosition = Duration.zero;

  // Dentro de _MainScreenState en MainScreen.dart

  void _playFavorite(String videoId) async {
    // 1. Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.yellow)),
    );

    try {
      final response = await http.get(
        Uri.parse('https://www.dailymotion.com/player/metadata/video/$videoId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Navigator.pop(context); // Quitar loading

        setState(() {
          // IMPORTANTE: Creamos una lista con un solo video (el favorito)
          // para que el Feed vertical se resetee y muestre este video primero.
          _currentVideoData = data;
          _lastGlobalPosition = Duration.zero;
          _selectedIndex = 1; // Pestaña For You
          _innerHorizontalIndex = 0; // Página del Video
        });

        // Aseguramos que el PageView horizontal vuelva a la posición del video
        if (_forYouHorizontalController.hasClients) {
          _forYouHorizontalController.jumpToPage(0);
        }

        _showCustomSnackBar(
          "Reproduciendo: ${data['title']}",
          icon: Icons.play_arrow,
        );
      }
    } catch (e) {
      Navigator.pop(context);
      _showCustomSnackBar("Error al cargar favorito", color: Colors.red);
    }
  }

  void _showCustomSnackBar(String message, {IconData? icon, Color? color}) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color ?? Colors.grey[900]!.withValues(alpha: 0.95),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(15, 0, 15, 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onNavigationTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _backToVertical() async {
    // 1. Forzar vertical
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // 2. Mostrar barras del sistema
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // 3. Volver a la página 0 (Feed) con animación
    if (_forYouHorizontalController.hasClients && _selectedIndex == 1) {
      await _forYouHorizontalController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    // 4. Actualizar el índice interno para que el AppBar cambie
    setState(() {
      _innerHorizontalIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDetailsVisible = _selectedIndex == 1 && _innerHorizontalIndex == 1;
    bool hideAppBar = _selectedIndex == 2 || _selectedIndex == 3;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (_innerHorizontalIndex == 1) {
          _backToVertical();
          return;
        }
        if (_selectedIndex != 1) {
          _onNavigationTap(1);
          return;
        }
        if (didPop) return;

        final now = DateTime.now();
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          _showCustomSnackBar('Press again to exit', icon: Icons.exit_to_app);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        // IMPORTANTE: Esto evita que el video "salte" hacia arriba al quitar el AppBar
        extendBodyBehindAppBar: true,
        appBar: hideAppBar
            ? null
            : AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                // Busca esta parte en tu AppBar:
                leading: isDetailsVisible
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new),
                        // CAMBIA ESTO:
                        onPressed: _backToVertical,
                      )
                    : IconButton(
                        icon: const Icon(Icons.favorite_border, size: 28),
                        onPressed: () => _onNavigationTap(2),
                      ),
                title: isDetailsVisible
                    ? Text(
                        "EP $_currentEpFromChild",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildAppBarText("Explorer", 0),
                          const SizedBox(width: 20),
                          _buildAppBarText("For You", 1),
                        ],
                      ),
                actions: [
                  if (isDetailsVisible)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.grid_view_rounded,
                          color: Colors.black,
                          size: 22,
                        ),
                        onPressed: () => _openModalFromAppBar?.call(),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.search, size: 28),
                      onPressed: () => _onNavigationTap(3),
                    ),
                ],
              ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            ExplorerView(),
            PageView(
              controller: _forYouHorizontalController,
              onPageChanged: (index) =>
                  setState(() => _innerHorizontalIndex = index),
              children: [
                // PAGINA 0: EL FEED VERTICAL
                VideoVerticalFeed(
                  // IMPORTANTE: Esta Key guarda la posición del scroll
                  key: const PageStorageKey('feed_scroll_pos'),
                  isVisible: _selectedIndex == 1 && _innerHorizontalIndex == 0,
                  initialPosition: _lastGlobalPosition,
                  onVideoChanged: (data) {
                    setState(() {
                      _currentVideoData = data;
                      // No reseteamos el tiempo aquí para evitar saltos bruscos
                    });
                  },
                  onLimitReached: () {
                    if (_innerHorizontalIndex == 0 &&
                        _lastGlobalPosition.inSeconds >= 120) {
                      _forYouHorizontalController.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  onTimePositionChanged: (position) {
                    // Guardamos la posición sin llamar a setState cada milisegundo
                    _lastGlobalPosition = position;
                  },
                  initialVideoId: widget.initialVideoId,
                ),

                // PAGINA 1: LOS SEGMENTOS
                VideoSegmentsView(
                  videoData: _currentVideoData,
                  isVisible: _selectedIndex == 1 && _innerHorizontalIndex == 1,
                  initialPosition: _lastGlobalPosition,
                  onTimeUpdate: (pos) => _lastGlobalPosition = pos,
                  onEpChanged: (ep, openModal) {
                    setState(() {
                      _currentEpFromChild = ep;
                      _openModalFromAppBar = openModal;
                    });
                  },
                  onVisibilityChanged: (visible) {
                    hideAppBar =
                        !visible; // Si visible es false, ocultamos el AppBar
                  },
                ),
              ],
            ),
            // Favoritos
            FavoritesScreen(
              onPlayVideo: _playFavorite,
              isActive: _selectedIndex == 2,
            ),

            // --- NUEVO BUSCADOR ---
            SearchVideosView(
              onVideoTap: (videoData) {
                // Usamos la misma lógica que en favoritos para reproducir
                _playFavorite(videoData['id']);
              },
            ),
          ],
        ),
        bottomNavigationBar: isDetailsVisible
            ? null
            : BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.black,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white60,
                currentIndex: _selectedIndex,
                onTap: _onNavigationTap,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.explore),
                    label: 'Explorer',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.houseboat_outlined),
                    label: 'For You',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.favorite_border),
                    label: 'Favorite',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.search),
                    label: 'Search',
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAppBarText(String text, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onNavigationTap(index),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : Colors.white60,
        ),
      ),
    );
  }
}
