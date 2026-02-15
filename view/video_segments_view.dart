import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:stack_appodeal_flutter/stack_appodeal_flutter.dart';

// Tus imports de widgets personalizados
import 'package:cuecue/widget/fade_in_button.dart';
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
  final Function(bool) onVisibilityChanged;

  const VideoSegmentsView({
    super.key,
    this.videoData,
    required this.onEpChanged,
    required this.onTimeUpdate,
    this.startInEpisodeTwo = false,
    this.isVisible = true,
    this.initialPosition = Duration.zero,
    required this.onVisibilityChanged,
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

  int _scrollCounter = 0;
  Timer? _adTimer;
  bool _isAdShowing = false;

  Timer? _hideTimer;
  bool _showControls = true;

  bool _showHeartIcon = false;
  bool _showPlayIcon = false;
  bool _isIconPlaying = false;
  bool _showFullVideoButton = false;

  @override
  void initState() {
    super.initState();
    _currentEp = widget.initialPosition.inSeconds ~/ 120;
    if (widget.startInEpisodeTwo) _currentEp = 1;
    _episodeController = PageController(initialPage: _currentEp);
    _initEpisodePlayer();
    _startAdTimer();
    _setupAdCallbacks();
    _resetHideTimer();
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (!_showControls) {
      setState(() => _showControls = true);
      widget.onVisibilityChanged(true);
    }
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showControls = false);
        widget.onVisibilityChanged(false);
      }
    });
  }

  void _setupAdCallbacks() {
    Appodeal.setInterstitialCallbacks(
      onInterstitialShown: () {
        if (mounted) setState(() => _isAdShowing = true);
        _playerController?.pause();
      },
      onInterstitialClosed: () {
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
      if (widget.isVisible && !_isAdShowing) _showInterstitial();
    });
  }

  Future<void> _showInterstitial() async {
    bool isLoaded = await Appodeal.isLoaded(AppodealAdType.Interstitial);
    if (isLoaded) Appodeal.show(AppodealAdType.Interstitial);
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
        }

        setState(() => _isInitialized = true);
        if (widget.isVisible && !_isAdShowing) _playerController!.play();
        widget.onEpChanged(_currentEp + 1, _showSheet);
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _videoListener() {
    if (_playerController == null || !_playerController!.value.isInitialized)
      return;
    final position = _playerController!.value.position;
    final bool isVideoHorizontal = _playerController!.value.aspectRatio > 1.0;

    if (position.inSeconds >= 10 &&
        !_showFullVideoButton &&
        isVideoHorizontal) {
      setState(() => _showFullVideoButton = true);
    } else if ((position.inSeconds < 10 || !isVideoHorizontal) &&
        _showFullVideoButton) {
      setState(() => _showFullVideoButton = false);
    }

    if (widget.isVisible && _playerController!.value.isPlaying) {
      widget.onTimeUpdate(position);
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
    _resetHideTimer();
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
    // 1. PREVENCIÓN DE ERROR: Si los datos aún no llegan, devolvemos un fondo negro
    // Esto evita el NoSuchMethodError y mantiene la app corriendo.
    if (widget.videoData == null) {
      return Container(color: Colors.black);
    }

    // 2. EXTRACCIÓN SEGURA DE DATOS
    final int duration = widget.videoData['duration'] ?? 0;
    final int totalSegments = (duration <= 0) ? 1 : (duration / 120).ceil();

    // Manejo de miniaturas tanto para la estructura de Dailymotion como para tu mapa interno
    final dynamic thumbs = widget.videoData['thumbnails'];
    final String? thumbnailUrl = (thumbs != null)
        ? (thumbs['1080'] ?? thumbs['720'])
        : (widget.videoData['thumbnail_1080_url'] ??
              widget.videoData['thumbnail_720_url']);

    return PageView.builder(
      controller: _episodeController,
      scrollDirection: Axis.vertical,
      itemCount: totalSegments,
      // allowImplicitScrolling es CLAVE: Carga el siguiente segmento en memoria
      // antes de que el usuario llegue a él, eliminando el lag.
      allowImplicitScrolling: true,
      onPageChanged: (index) {
        if (!mounted) return;
        _resetHideTimer();
        setState(() => _currentEp = index);

        // Notificamos el cambio de episodio al padre
        widget.onEpChanged(index + 1, _showSheet);

        // Mover el video a la posición del segmento (120 segundos por segmento)
        final newPos = Duration(seconds: index * 120);
        _playerController?.seekTo(newPos);

        // LÓGICA DE ANUNCIOS: Usamos Future.microtask para que el anuncio
        // no interrumpa la animación del scroll.
        _scrollCounter++;
        if (_scrollCounter >= 4) {
          _scrollCounter = 0;
          Future.microtask(() => _showInterstitial());
        }
      },
      itemBuilder: (context, index) {
        return OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;

            // --- LÓGICA DE AJUSTE DINÁMICO ---
            BoxFit dynamicFit = BoxFit.contain;
            bool useFullExpansion = false;

            if (_isInitialized && _playerController != null) {
              final videoAspectRatio = _playerController!.value.aspectRatio;
              if (isLandscape) {
                dynamicFit = BoxFit.fill;
                useFullExpansion = true;
              } else {
                if (videoAspectRatio < 1.0) {
                  dynamicFit =
                      BoxFit.cover; // Pantalla completa para videos verticales
                  useFullExpansion = true;
                } else {
                  dynamicFit = BoxFit.contain; // Proporcional para horizontales
                  useFullExpansion = false;
                }
              }
            }

            return GestureDetector(
              onTap: _handleTogglePlay,
              onDoubleTap: () async {
                final vidId = widget.videoData['id'];
                if (vidId != null) {
                  await VideoLogicHelper.toggleFavorite(vidId);
                  if (mounted) setState(() => _showHeartIcon = true);
                  Future.delayed(const Duration(milliseconds: 800), () {
                    if (mounted) setState(() => _showHeartIcon = false);
                  });
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Fondo base
                  Container(color: Colors.black),

                  // MINIATURA DE CARGA RÁPIDA
                  // Se muestra solo si el video no está listo.
                  // gaplessPlayback evita parpadeos blancos.
                  if (thumbnailUrl != null && !_isInitialized)
                    Image.network(
                      thumbnailUrl,
                      fit: isLandscape ? BoxFit.fill : BoxFit.contain,
                      gaplessPlayback: true,
                    ),

                  // RENDERIZADO DEL VIDEO
                  if (_isInitialized && _playerController != null)
                    Center(
                      child: useFullExpansion
                          ? SizedBox.expand(
                              child: FittedBox(
                                fit: dynamicFit,
                                clipBehavior: Clip.hardEdge,
                                child: SizedBox(
                                  width: _playerController!.value.size.width,
                                  height: _playerController!.value.size.height,
                                  child: VideoPlayer(_playerController!),
                                ),
                              ),
                            )
                          : AspectRatio(
                              aspectRatio: _playerController!.value.aspectRatio,
                              child: VideoPlayer(_playerController!),
                            ),
                    ),

                  // CAPA DE CONTROLES (Solo si el video ya cargó)
                  if (_isInitialized)
                    AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: IgnorePointer(
                        ignoring: !_showControls,
                        child: Stack(
                          children: [
                            UIOverlayWidget(
                              playerController: _playerController,
                              currentEp: _currentEp + 1,
                              title: widget.videoData['title'] ?? '',
                              videoId: widget.videoData['id'] ?? '',
                            ),
                            // Botón de pantalla completa
                            if (_showFullVideoButton)
                              _buildFullScreenButton(isLandscape, context),
                          ],
                        ),
                      ),
                    ),

                  // ICONOS DE FEEDBACK (Corazón / Play / Pause)
                  if (_showHeartIcon)
                    _buildCenterIcon(Icons.favorite, Colors.redAccent),
                  if (_showPlayIcon && !_showHeartIcon)
                    _buildCenterIcon(
                      _isIconPlaying
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      Colors.white,
                      withBackground: true,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Widget auxiliar para los iconos centrales (evita repetir código)
  Widget _buildCenterIcon(
    IconData icon,
    Color color, {
    bool withBackground = false,
  }) {
    return Center(
      child: Container(
        padding: withBackground ? const EdgeInsets.all(15) : EdgeInsets.zero,
        decoration: withBackground
            ? const BoxDecoration(color: Colors.black38, shape: BoxShape.circle)
            : null,
        child: Icon(icon, size: withBackground ? 70 : 110, color: color),
      ),
    );
  }

  // Widget auxiliar para el botón de pantalla completa
  // Widget auxiliar para el botón de pantalla completa en VideoSegmentsView
  Widget _buildFullScreenButton(bool isLandscape, BuildContext context) {
    return Positioned(
      // Mantenemos la posición dinámica según la orientación
      bottom: isLandscape ? 30 : MediaQuery.of(context).size.height * 0.25,
      left: 0,
      right: 0,
      child: Center(
        child: FadeInButton(
          isLandscape: isLandscape,
          onPressed: () async {
            _resetHideTimer();

            if (isLandscape) {
              // --- SALIR DE PANTALLA COMPLETA ---
              await SystemChrome.setPreferredOrientations([
                DeviceOrientation.portraitUp,
              ]);
              await SystemChrome.setEnabledSystemUIMode(
                SystemUiMode.edgeToEdge,
              );
            } else {
              // --- ENTRAR A PANTALLA COMPLETA (Tu lógica anterior) ---

              // 1. Girar el dispositivo
              await SystemChrome.setPreferredOrientations([
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]);

              // Poner modo inmersivo (oculta barras de sistema)
              await SystemChrome.setEnabledSystemUIMode(
                SystemUiMode.immersiveSticky,
              );

              // 2. Pequeña espera para que la rotación termine
              await Future.delayed(const Duration(milliseconds: 200));

              // 3. Cambiar el tiempo y sincronizar el estado
              // Notificamos al padre (como hacias antes con widget.onTimeUpdate(120))
              widget.onTimeUpdate(const Duration(seconds: 120));

              // IMPORTANTE: También movemos el reproductor interno
              // y el controlador de páginas al segmento correspondiente
              if (_playerController != null) {
                await _playerController!.seekTo(const Duration(seconds: 120));
              }

              // Si el segmento 1 empieza en el segundo 120, movemos la página:
              _episodeController.jumpToPage(1);
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    _hideTimer?.cancel();
    _playerController?.removeListener(_videoListener);
    _playerController?.dispose();
    _episodeController.dispose();
    super.dispose();
  }
}
