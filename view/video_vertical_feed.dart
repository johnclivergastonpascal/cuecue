import 'dart:async'; // Necesario para el Timer
import 'dart:convert';
import 'dart:math';
import 'package:cuecue/view/video_player_item.dart';
import 'package:cuecue/widget/tiktok_loader.dart';
import 'package:cuecue/widget/videoListenAndToggleplay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:stack_appodeal_flutter/stack_appodeal_flutter.dart'; // Importar Appodeal

class VideoVerticalFeed extends StatefulWidget {
  final Function(dynamic) onVideoChanged;
  final VoidCallback onLimitReached;
  final Function(Duration) onTimePositionChanged;
  final bool isVisible;
  final Duration initialPosition;
  final String? initialVideoId;

  const VideoVerticalFeed({
    super.key,
    required this.onVideoChanged,
    required this.onLimitReached,
    required this.onTimePositionChanged,
    required this.isVisible,
    required this.initialPosition,
    required this.initialVideoId,
  });

  @override
  State<VideoVerticalFeed> createState() => _VideoVerticalFeedState();
}

class _VideoVerticalFeedState extends State<VideoVerticalFeed>
    with AutomaticKeepAliveClientMixin {
  List<dynamic> videos = [];
  bool isLoading = false;
  int currentPage = 1;
  bool hasMore = true;
  int _currentIndex = 0;

  // --- LÓGICA DE ANUNCIOS ---
  int _scrollCounter = 0; // Contador de scrolls
  Timer? _adTimer; // Timer para los 10 minutos

  bool _showHeartIcon = false;
  String? _favoriteVideoIdTrigger;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    currentPage = Random().nextInt(20) + 1;
    _fetchVideos();
    _fetchVideos().then((_) {
      if (widget.initialVideoId != null) {
        final index = videos.indexWhere(
          (v) => v['id'] == widget.initialVideoId,
        );
        if (index != -1) {
          _currentIndex = index;
        }
      }
    });
    _startAdTimer(); // Iniciar cronómetro de 10 min
  }

  @override
  void dispose() {
    _adTimer?.cancel(); // Limpiar el timer al cerrar
    super.dispose();
  }

  // Timer: Ejecuta cada 10 minutos
  void _startAdTimer() {
    _adTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _showInterstitial();
    });
  }

  // Función para mostrar el anuncio si está cargado
  Future<void> _showInterstitial() async {
    bool isLoaded = await Appodeal.isLoaded(AppodealAdType.Interstitial);
    if (isLoaded && mounted) {
      Appodeal.show(AppodealAdType.Interstitial);
    } else {
      debugPrint("El Interstitial aún no está listo");
    }
  }

  // Resto de funciones (fetch, precache, handleDoubleTap)...
  void _precacheThumbnails(List<dynamic> newVideos) {
    for (var video in newVideos) {
      if (video['thumbnail_1080_url'] != null) {
        precacheImage(NetworkImage(video['thumbnail_1080_url']), context);
      }
    }
  }

  Future<void> _fetchVideos() async {
    if (isLoading || !hasMore) return;
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.dailymotion.com/user/CinePulseChannel/videos?fields=id,title,duration,thumbnail_1080_url,thumbnail_720_url&limit=10&page=$currentPage',
        ),
      );
      if (response.statusCode == 200) {
        final list = json.decode(response.body)['list'] as List;
        if (mounted) {
          list.shuffle();
          _precacheThumbnails(list);
          setState(() {
            videos.addAll(list);
            isLoading = false;
            currentPage++;
            if (list.length < 10) hasMore = false;
          });
          if (videos.isNotEmpty && videos.length <= 10) {
            widget.onVideoChanged(videos[0]);
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleDoubleTap(String videoId) async {
    await VideoLogicHelper.toggleFavorite(videoId);
    HapticFeedback.heavyImpact();
    setState(() {
      _favoriteVideoIdTrigger = videoId;
      _showHeartIcon = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showHeartIcon = false;
          _favoriteVideoIdTrigger = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (videos.isEmpty && isLoading) {
      return const Center(child: TikTokLoader(size: 25));
    }

    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: hasMore ? videos.length + 1 : videos.length,
      allowImplicitScrolling: true,
      onPageChanged: (index) {
        if (index < videos.length) {
          setState(() => _currentIndex = index);
          widget.onVideoChanged(videos[index]);
          widget.onTimePositionChanged(Duration.zero);

          // --- LÓGICA DE CADA 5 SCROLLS ---
          _scrollCounter++;
          if (_scrollCounter >= 4) {
            _scrollCounter = 0; // Reiniciar contador
            _showInterstitial(); // Mostrar anuncio
          }
        }
        if (index >= videos.length - 3 && hasMore && !isLoading) {
          _fetchVideos();
        }
      },
      itemBuilder: (context, index) {
        if (index == videos.length) {
          return const Center(child: TikTokLoader(size: 25));
        }

        final videoData = videos[index];
        final String videoId = videoData['id'];

        return GestureDetector(
          onDoubleTap: () => _handleDoubleTap(videoId),
          child: Stack(
            fit: StackFit.expand,
            children: [
              VideoPlayerItem(
                key: ValueKey("player_$videoId"),
                videoId: videoId,
                title: videoData['title'] ?? 'Sin título',
                thumbnails: {
                  '1080': videoData['thumbnail_1080_url'],
                  '720': videoData['thumbnail_720_url'],
                },
                initialPosition: index == _currentIndex
                    ? widget.initialPosition
                    : Duration.zero,
                onTimeUpdate: (seconds) {
                  widget.onTimePositionChanged(Duration(seconds: seconds));
                  if (widget.isVisible &&
                      index == _currentIndex &&
                      seconds == 120) {
                    widget.onLimitReached();
                  }
                },
                shouldPlay: index == _currentIndex && widget.isVisible,
              ),
              if (_showHeartIcon && _favoriteVideoIdTrigger == videoId)
                Center(
                  child: TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 400),
                    tween: Tween<double>(begin: 0.0, end: 1.2),
                    curve: Curves.elasticOut,
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.redAccent,
                          size: 110,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 10),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
