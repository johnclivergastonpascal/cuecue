import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class BuildSliderWidget extends StatefulWidget {
  final VideoPlayerController? playerController;
  final int currentEp;

  const BuildSliderWidget({
    super.key,
    required this.playerController,
    required this.currentEp,
  });

  @override
  State<BuildSliderWidget> createState() => _BuildSliderWidgetState();
}

class _BuildSliderWidgetState extends State<BuildSliderWidget> {
  double? _draggingValue; // Valor temporal mientras el usuario arrastra

  @override
  Widget build(BuildContext context) {
    if (widget.playerController == null) return const SizedBox.shrink();

    return ValueListenableBuilder(
      valueListenable: widget.playerController!,
      builder: (context, VideoPlayerValue value, child) {
        // 1. Calculamos la posición actual real (0 a 120)
        int absoluteSeconds = value.position.inSeconds;
        int startOfEp =
            (widget.currentEp - 1) * 120; // currentEp viene como 1, 2, 3...

        double currentPos = (absoluteSeconds - startOfEp).toDouble();

        // 2. Si el usuario está arrastrando, usamos el valor del dedo.
        // Si no, usamos el valor del video.
        double sliderValue = _draggingValue ?? currentPos;

        return SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbColor: Colors.white,
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white24,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 4,
            ), // Un poco de radio para poder tocarlo
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: SizedBox(
            height: 20,
            child: Slider(
              value: sliderValue.clamp(0.0, 120.0),
              min: 0.0,
              max: 120.0,
              onChangeStart: (v) {
                setState(() => _draggingValue = v);
              },
              onChanged: (v) {
                setState(() => _draggingValue = v);
              },
              onChangeEnd: (v) {
                // Al soltar, calculamos la posición global y hacemos el seek
                final seekToSecs = ((widget.currentEp - 1) * 120) + v.toInt();
                widget.playerController?.seekTo(Duration(seconds: seekToSecs));

                // Limpiamos el valor de arrastre después de un pequeño delay
                // para evitar que la barra "salte" antes de que el video cargue el nuevo punto
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) setState(() => _draggingValue = null);
                });
              },
            ),
          ),
        );
      },
    );
  }
}
