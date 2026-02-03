import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final Function(Color) onColorTap; // Callback
  final Function(Color, String) onColorChanged;
  const HomeScreen({
    super.key,
    required this.onColorTap,
    required this.onColorChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Color> colors = [Colors.red, Colors.green, Colors.blue, Colors.yellow];
  List<Map<String, dynamic>> datos = [
    {'color': Colors.red, 'nombre': 'Rojo'},
    {'color': Colors.green, 'nombre': 'Verde'},
    {'color': Colors.blue, 'nombre': 'Azul'},
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PageView.builder(
      key: const PageStorageKey('homeScroll'),
      scrollDirection: Axis.vertical,
      onPageChanged: (index) =>
          widget.onColorChanged(datos[index]['color'], datos[index]['nombre']),
      itemCount: datos.length,
      itemBuilder: (context, index) {
        Color color = datos[index]['color'];
        return GestureDetector(
          onTap: () => widget.onColorTap(color),
          child: Container(
            color: color,
            child: const Center(child: Text("Tócame para ir a detalles")),
          ),
        );
      },
    );
  }
}
