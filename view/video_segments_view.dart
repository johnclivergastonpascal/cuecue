import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:stack_appodeal_flutter/stack_appodeal_flutter.dart';

import 'package:cuecue/widget/build_ui_overlay.dart';
import 'package:cuecue/widget/episode_sheet_helper.dart';
import 'package:cuecue/widget/videoListenAndToggleplay.dart';

class VideoSegmentsView extends StatefulWidget {
  final dynamic videoData;
  final bool startInEpisodeTwo;
  final Function(int, VoidCallback) onEpChanged;
  final bool isVisible;
  final Duration initialPosition;
  final Function(Duration) onTimeUpdate;

  const VideoSegmentsView({
    super.key,
    this.videoData,
    required this.onEpChanged,
    required this.onTimeUpdate,
    this.startInEpisodeTwo = false,
    this.isVisible = true,
    this.initialPosition = Duration.zero,
  });

  @override
  State<VideoSegmentsView> createState() => _VideoSegmentsViewState();
}

class _VideoSegmentsViewState extends State<VideoSegmentsView> {
  late PageController _episodeController;
  VideoPlayerController? _playerController;
  bool _isInitialized = false;
  int _currentEp = 0;
  String? _currentVideoId;

  // --- LÓGICA DE ANUNCIOS ---
  int _scrollCounter = 0;
  Timer? _adTimer;
  bool _isAdShowing = false;

  // Estados para animaciones
  bool _showHeartIcon = false;
  bool _showPlayIcon = false;
  bool _isIconPlaying = false;

  @override
  void initState() {
    super.initState();
    _currentEp = widget.initialPosition.inSeconds ~/ 120;
    if (widget.startInEpisodeTwo) _currentEp = 1;

    _episodeController = PageController(initialPage: _currentEp);
    _initEpisodePlayer();

    // Iniciar lógica de anuncios
    _startAdTimer();
    _setupAdCallbacks();
  }

  void _setupAdCallbacks() {
    Appodeal.setInterstitialCallbacks(
      onInterstitialShown: () {
        debugPrint("APPODEAL: Anuncio mostrado, pausando video");
        if (mounted) setState(() => _isAdShowing = true);
        _playerController?.pause();
      },
      onInterstitialClosed: () {
        debugPrint("APPODEAL: Anuncio cerrado, reanudando video");
        if (mounted) setState(() => _isAdShowing = false);
        if (widget.isVisible) _playerController?.play();
      },
      onInterstitialFailedToLoad: () {
        if (mounted) setState(() => _isAdShowing = false);
      },
    );
  }

  void _startAdTimer() {
    _adTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      if (widget.isVisible && !_isAdShowing) {
        debugPrint("LÓGICA: Timer de 10 min saltó");
        _showInterstitial();
      }
    });
  }

  // MÉDOTO PARA MOSTRAR ANUNCIO
  Future<void> _showInterstitial() async {
    bool isLoaded = await Appodeal.isLoaded(AppodealAdType.Interstitial);
    if (isLoaded) {
      Appodeal.show(AppodealAdType.Interstitial);
    } else {
      debugPrint("APPODEAL: El anuncio aún no está cargado");
    }
  }

  @override
  void didUpdateWidget(VideoSegmentsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_playerController != null && _isInitialized) {
      if (_isAdShowing) {
        _playerController!.pause();
        return;
      }
      if (!widget.isVisible && oldWidget.isVisible) {
        _playerController!.pause();
      } else if (widget.isVisible && !oldWidget.isVisible) {
        _playerController!.play();
      }
    }
    if (widget.videoData?['id'] != _currentVideoId) {
      _initEpisodePlayer();
    }
  }

  Future<void> _initEpisodePlayer() async {
    if (widget.videoData == null) return;
    final String newId = widget.videoData['id'];
    _currentVideoId = newId;

    if (_playerController != null) {
      _playerController!.removeListener(_videoListener);
      await _playerController!.dispose();
      _playerController = null;
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              'https://www.dailymotion.com/player/metadata/video/$newId',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final videoUrl = data['qualities']['auto'][0]['url'];
        final controller = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
        );
        await controller.initialize();

        if (!mounted || _currentVideoId != newId) {
          controller.dispose();
          return;
        }

        _playerController = controller;
        _playerController!.addListener(_videoListener);

        if (widget.startInEpisodeTwo) {
          await _playerController!.seekTo(const Duration(seconds: 120));
        } else if (widget.initialPosition > Duration.zero) {
          await _playerController!.seekTo(widget.initialPosition);
        } else if (_currentEp > 0) {
          await _playerController!.seekTo(Duration(seconds: _currentEp * 120));
        }

        setState(() => _isInitialized = true);
        if (widget.isVisible && !_isAdShowing) _playerController!.play();
        widget.onEpChanged(_currentEp + 1, _showSheet);
      }
    } catch (e) {
      debugPrint("Error inicializando VideoSegments: $e");
    }
  }

  void _videoListener() {
    if (_playerController == null || !_playerController!.value.isInitialized)
      return;
    if (_isAdShowing && _playerController!.value.isPlaying) {
      _playerController!.pause();
      return;
    }
    if (widget.isVisible && _playerController!.value.isPlaying) {
      widget.onTimeUpdate(_playerController!.value.position);
    }
    VideoLogicHelper.handleVideoListener(
      playerController: _playerController,
      episodeController: _episodeController,
      currentEp: _currentEp,
      videoDuration: widget.videoData['duration'] ?? 0,
    );
  }

  void _handleTogglePlay() {
    if (_playerController == null || !_isInitialized || _isAdShowing) return;
    setState(() {
      if (_playerController!.value.isPlaying) {
        _playerController!.pause();
        _isIconPlaying = false;
      } else {
        _playerController!.play();
        _isIconPlaying = true;
      }
      _showPlayIcon = true;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showPlayIcon = false);
    });
  }

  void _showSheet() => EpisodeSheetHelper.show(
    context: context,
    duration: widget.videoData['duration'] ?? 0,
    currentEp: _currentEp,
    controller: _episodeController,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, body: _buildVideoPager());
  }

  Widget _buildVideoPager() {
    final int duration = widget.videoData['duration'] ?? 0;
    final int totalSegments = (duration / 120).ceil();
    final String? thumbnailUrl =
        widget.videoData['thumbnails']?['1080'] ??
        widget.videoData['thumbnails']?['720'];

    return PageView.builder(
      controller: _episodeController,
      scrollDirection: Axis.vertical,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: totalSegments,
      onPageChanged: (index) {
        setState(() => _currentEp = index);
        widget.onEpChanged(index + 1, _showSheet);

        final newPosition = Duration(seconds: index * 120);
        _playerController?.seekTo(newPosition);
        widget.onTimeUpdate(newPosition);

        // --- AQUÍ ESTÁ LA LÓGICA DE LOS 5 EPISODIOS ---
        _scrollCounter++;
        debugPrint("CONTADOR DE EPISODIOS: $_scrollCounter / 5");

        if (_scrollCounter >= 4) {
          debugPrint("LÓGICA: Se alcanzó el límite de 5, mostrando anuncio...");
          _scrollCounter = 0; // Reiniciar contador
          _showInterstitial(); // Llamar al anuncio
        }

        if (widget.isVisible && !_isAdShowing) _playerController?.play();
      },
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: _handleTogglePlay,
          onDoubleTap: () async {
            await VideoLogicHelper.toggleFavorite(widget.videoData['id']);
            setState(() => _showHeartIcon = true);
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) setState(() => _showHeartIcon = false);
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumbnailUrl != null && !_isInitialized)
                Image.network(thumbnailUrl, fit: BoxFit.cover),
              if (_isInitialized && _playerController != null)
                Center(
                  child: AspectRatio(
                    aspectRatio: _playerController!.value.aspectRatio,
                    child: VideoPlayer(_playerController!),
                  ),
                ),
              if (_showHeartIcon)
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
                        ),
                      );
                    },
                  ),
                ),
              if (_showPlayIcon && !_showHeartIcon)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isIconPlaying
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      size: 70,
                      color: Colors.cyanAccent.withOpacity(0.9),
                    ),
                  ),
                ),
              UIOverlayWidget(
                playerController: _playerController,
                currentEp: _currentEp + 1,
                title: widget.videoData['title'] ?? '',
                videoId: widget.videoData['id'],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    _playerController?.removeListener(_videoListener);
    _playerController?.dispose();
    _episodeController.dispose();
    super.dispose();
  }
}
