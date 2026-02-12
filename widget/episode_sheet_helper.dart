import 'package:flutter/material.dart';

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
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: totalSegments,
        itemBuilder: (context, index) => InkWell(
          onTap: () {
            controller.jumpToPage(index);
            Navigator.pop(context);
          },
          child: Container(
            decoration: BoxDecoration(
              color: currentEp == index ? Colors.cyanAccent : Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                "Ep ${index + 1}",
                style: TextStyle(
                  color: currentEp == index ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
