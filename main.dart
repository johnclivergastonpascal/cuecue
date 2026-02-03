import 'package:cuecue/screen/details_screen.dart';
import 'package:cuecue/screen/favorites_screen.dart';
import 'package:cuecue/screen/home_screen.dart';
import 'package:cuecue/layout.dart';
import 'package:cuecue/screen/search_screen.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Material App',
      initialRoute: '/',
      routes: {
        '/': (context) => Layout(),
        '/home': (context) => HomeScreen(
          onColorTap: (Color p1) {},
          onColorChanged: (Color p1, String p2) {},
        ),
        '/details': (context) => DetailsScreen(),
        '/search': (context) => SearchScreen(),
        '/favorites': (context) => FavoritesScreen(),
      },
    );
  }
}
