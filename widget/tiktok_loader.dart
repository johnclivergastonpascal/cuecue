import 'package:flutter/material.dart';

class TikTokLoader extends StatefulWidget {
  final double size;

  const TikTokLoader({super.key, this.size = 40.0});

  @override
  State<TikTokLoader> createState() => _TikTokLoaderState();
}

class _TikTokLoaderState extends State<TikTokLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    // Curva de movimiento suave para el rebote
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size * 2,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Bola Cyan (Derecha a Izquierda)
              Transform.translate(
                offset: Offset(
                  lerpDouble(
                    -widget.size / 2,
                    widget.size / 2,
                    _animation.value,
                  ),
                  0,
                ),
                child: _Dot(
                  color: const Color(0xFF25F4EE), // TikTok Cyan
                  size: widget.size,
                  // El truco del Z-Index: cambia el orden según la animación
                  isFront: _controller.value < 0.5,
                ),
              ),
              // Bola Rosa (Izquierda a Derecha)
              Transform.translate(
                offset: Offset(
                  lerpDouble(
                    widget.size / 2,
                    -widget.size / 2,
                    _animation.value,
                  ),
                  0,
                ),
                child: _Dot(
                  color: const Color(0xFFFE2C55), // TikTok Pink
                  size: widget.size,
                  isFront: _controller.value >= 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Función auxiliar para interpolar números sin importar dart:ui
  double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

class _Dot extends StatelessWidget {
  final Color color;
  final double size;
  final bool isFront;

  const _Dot({required this.color, required this.size, required this.isFront});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 0.6,
      height: size * 0.6,
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        shape: BoxShape.circle,
        // Mezcla de colores sutil cuando se cruzan
        backgroundBlendMode: BlendMode.screen,
      ),
    );
  }
}
