import 'package:cuecue/screen/details_screen.dart';
import 'package:cuecue/screen/home_screen.dart';
import 'package:cuecue/widget/app_bar.dart';
import 'package:flutter/material.dart';

class Layout extends StatefulWidget {
  const Layout({super.key});

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  // list routes of pages
  List<String> pageRoutes = ['/home', '/details', '/search', '/favorites'];
  // routes name
  Map<String, WidgetBuilder>? get routes =>
      context.findAncestorWidgetOfExactType<MaterialApp>()?.routes;
  // Page controller
  PageController pageController = PageController();

  // Variable para guardar el dato que queremos pasar
  Color colorSeleccionado = Colors.grey;
  String nombreColor = "grey"; // Nombre inicial

  void actualizarColor(Color nuevoColor, String nuevoNombre) {
    // Solo actualizamos si el color es distinto para evitar redibujos innecesarios
    if (nombreColor != nuevoNombre) {
      setState(() {
        colorSeleccionado = nuevoColor;
        nombreColor = nuevoNombre;
      });
    }
  }

  // Función para navegar dentro del PageView pasando datos
  void navegarADetalles(Color color) {
    setState(() {
      colorSeleccionado = color;
    });
    pageController.animateToPage(
      1, // Índice de /details
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(pageController, pageRoutes, nombreColor),
      body: PageView.builder(
        itemCount: pageRoutes.length,
        controller: pageController,
        itemBuilder: (context, index) {
          String routeName = pageRoutes[index];

          // Si es la Home, le pasamos la función para navegar
          if (routeName == '/home') {
            return HomeScreen(
              onColorTap: navegarADetalles,
              onColorChanged: actualizarColor,
            );
          }

          // Si es Details, le pasamos el color guardado
          if (routeName == '/details') {
            return DetailsScreen(color: colorSeleccionado);
          }

          WidgetBuilder? builder = routes?[routeName];
          return builder != null
              ? builder(context)
              : Center(child: Text('No route defined for $routeName'));
        },
      ),
    );
  }
}
