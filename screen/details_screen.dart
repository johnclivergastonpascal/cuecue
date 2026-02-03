import 'package:flutter/material.dart';

class DetailsScreen extends StatelessWidget {
  final color; // Recibe el dato
  const DetailsScreen({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color, // ¡Ahora el fondo es el color que tocaste en Home!
      child: Center(
        child: Text(
          "Vengo desde Home",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
