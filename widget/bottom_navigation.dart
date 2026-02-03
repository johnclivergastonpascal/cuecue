import 'package:flutter/material.dart';

Container bottomNavigationWidget(
  PageController controller,
  List<String> pageRoutes,
) {
  return Container(
    height: 60,
    width: double.infinity,
    color: Colors.blue,
    child: const Center(
      child: Text(
        'Bottom Navigation Bar',
        style: TextStyle(color: Colors.white, fontSize: 20),
      ),
    ),
  );
}
