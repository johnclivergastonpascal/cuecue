import 'package:flutter/material.dart';

class FadeInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLandscape;

  const FadeInButton({
    super.key,
    required this.onPressed,
    this.isLandscape = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // --- AJUSTA ESTE VALOR PARA SUBIRLO MÁS ---
      padding: EdgeInsets.only(bottom: isLandscape ? 65 : 60),
      child: TweenAnimationBuilder<double>(
        key: ValueKey(isLandscape),
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          // Ajuste de posición inicial de la animación
          double offsetX = isLandscape ? (40 * (1 - value)) : 0.0;
          double offsetY = isLandscape ? 0.0 : (40 * (1 - value));

          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(offsetX, offsetY),
              child: child,
            ),
          );
        },
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white24,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: const BorderSide(color: Colors.white30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          icon: Icon(isLandscape ? Icons.fullscreen_exit : Icons.fullscreen),
          label: Text(
            isLandscape ? "Salir de pantalla completa" : "Ver completo",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
