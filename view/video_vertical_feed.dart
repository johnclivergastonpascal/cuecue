import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cuecue/widget/video_player_item.dart';
import 'package:cuecue/widget/tiktok_loader.dart';
import 'package:cuecue/widget/videoListenAndToggleplay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stack_appodeal_flutter/stack_appodeal_flutter.dart';

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

  // Controlador para manejo preciso del scroll
  late PageController _pageController;

  int _scrollCounter = 0;
  Timer? _adTimer;
  bool _showHeartIcon = false;
  String? _favoriteVideoIdTrigger;
  Set<String> _shownVideoIds = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadHistoryAndFetch();
    _startAdTimer();
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAdTimer() {
    _adTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _showInterstitial();
    });
  }

  Future<void> _showInterstitial() async {
    bool isLoaded = await Appodeal.isLoaded(AppodealAdType.Interstitial);
    if (isLoaded && mounted) {
      Appodeal.show(AppodealAdType.Interstitial);
    }
  }

  Future<void> _loadHistoryAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? history = prefs.getStringList('seen_videos');
    if (history != null) {
      _shownVideoIds = history.toSet();
    }
    await _fetchVideos();

    // Si venimos de otra pantalla con un ID específico, buscamos su posición
    if (widget.initialVideoId != null && videos.isNotEmpty) {
      final index = videos.indexWhere((v) => v['id'] == widget.initialVideoId);
      if (index != -1) {
        setState(() => _currentIndex = index);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) _pageController.jumpToPage(index);
        });
      }
    }
  }

  Future<void> _fetchVideos() async {
    if (isLoading || !hasMore) return;
    setState(() => isLoading = true);

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
            'https://api.dailymotion.com/user/$channel/videos?fields=id,title,duration,thumbnail_1080_url,thumbnail_720_url&limit=20&page=$currentPage',
          ),
        ),
      );

      final responses = await Future.wait(requests);
      List newUniqueVideos = [];

      for (var response in responses) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body)['list'] as List;
          for (var video in data) {
            // SOLUCIÓN: Solo agregamos si el video tiene ID y Título (no nulos)
            if (video['id'] != null && !_shownVideoIds.contains(video['id'])) {
              newUniqueVideos.add(video);
            }
          }
        }
      }

      if (mounted) {
        newUniqueVideos.shuffle();
        setState(() {
          videos.addAll(newUniqueVideos);
          isLoading = false;
          currentPage++;
        });

        // Notificamos al padre sobre el primer video de inmediato para evitar errores de UI
        if (videos.isNotEmpty && _currentIndex == 0) {
          widget.onVideoChanged(videos[0]);
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
      if (mounted)
        setState(() {
          _showHeartIcon = false;
          _favoriteVideoIdTrigger = null;
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (videos.isEmpty) {
      return const Center(child: TikTokLoader(size: 25));
    }

    return RefreshIndicator(
      onRefresh: () async {
        videos.clear();
        currentPage = Random().nextInt(10) + 1;
        await _fetchVideos();
      },
      color: Colors.white,
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: hasMore ? videos.length + 1 : videos.length,
        allowImplicitScrolling: true,
        onPageChanged: (index) {
          if (index < videos.length) {
            setState(() => _currentIndex = index);
            widget.onVideoChanged(videos[index]);
            widget.onTimePositionChanged(Duration.zero);

            _scrollCounter++;
            if (_scrollCounter >= 5) {
              _scrollCounter = 0;
              _showInterstitial();
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
              children: [
                VideoPlayerItem(
                  key: ValueKey("player_$videoId"),
                  videoId: videoId,
                  title: videoData['title'] ?? '',
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

                // Animación de Corazón
                if (_showHeartIcon && _favoriteVideoIdTrigger == videoId)
                  Center(
                    child: TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 400),
                      tween: Tween<double>(begin: 0.0, end: 1.2),
                      curve: Curves.elasticOut,
                      builder: (_, double value, __) => Transform.scale(
                        scale: value,
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.redAccent,
                          size: 110,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
