import 'package:flutter/material.dart';

AppBar appBarWidget(
  PageController controller,
  List<String> pageRoutes,
  String nombreColor,
) {
  int searchIndex = pageRoutes.indexOf('/search');

  return AppBar(
    title: Text('CueCue App - $nombreColor'),
    centerTitle: true,
    // Usamos AnimatedBuilder para envolver TODO el contenido que cambia
    leading: AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double currentPage = controller.hasClients ? controller.page ?? 0 : 0;

        // Mostrar botón de atrás solo si NO estamos en la página inicial (index 0)
        if (currentPage > 0.5) {
          return IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              controller.animateToPage(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    ),
    actions: [
      AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          double currentPage = controller.hasClients ? controller.page ?? 0 : 0;

          // Ocultar búsqueda si estamos en la página de búsqueda
          if ((currentPage - searchIndex).abs() < 0.5) {
            return const SizedBox.shrink();
          }

          return IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              controller.animateToPage(
                searchIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          );
        },
      ),
    ],
  );
}
