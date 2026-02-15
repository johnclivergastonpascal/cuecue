import 'package:flutter/material.dart';
import 'dart:ui';

class EpisodeSheetHelper {
  static void show({
    required BuildContext context,
    required int duration,
    required int currentEp,
    required PageController controller,
  }) {
    final int totalSegments = (duration / 120).ceil();

    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent, // Transparente para ver el desenfoque
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 12,
            sigmaY: 12,
          ), // Efecto Glassmorphism
          child: Container(
            height:
                MediaQuery.of(context).size.height *
                0.5, // Altura media pantalla
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                // Indicador de arrastre superior (Handler)
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white38,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const Text(
                  "Seleccionar Episodio",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 15,
                          crossAxisSpacing: 15,
                          childAspectRatio:
                              1.1, // Hace los botones un poco más estéticos
                        ),
                    itemCount: totalSegments,
                    itemBuilder: (context, index) {
                      final bool isSelected = (currentEp - 1) == index;

                      return InkWell(
                        onTap: () {
                          controller.jumpToPage(index);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(15),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            // Gradiente si está seleccionado, si no, fondo sutil
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [
                                      Colors.cyanAccent,
                                      Colors.blueAccent,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isSelected
                                ? null
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.cyanAccent
                                  : Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.cyanAccent.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${index + 1}",
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  "EP",
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.black.withOpacity(0.6)
                                        : Colors.white38,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
