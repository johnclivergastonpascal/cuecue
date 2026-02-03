import 'package:cuecue/models/video_model.dart';
import 'package:flutter/material.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final video = ModalRoute.of(context)!.settings.arguments as VideoModel;

    return Scaffold(
      appBar: AppBar(title: const Text("Detalles del Video")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              video.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text("Duración: ${video.duration} seg"),
            Text("ID: ${video.id}"),
          ],
        ),
      ),
    );
  }
}
