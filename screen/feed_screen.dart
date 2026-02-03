import 'package:cuecue/models/video_model.dart';
import 'package:cuecue/widgets/video_tile.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ApiService _api = ApiService();
  late Future<List<VideoModel>> _videosFuture;

  @override
  void initState() {
    super.initState();
    _videosFuture = _api.fetchAllVideos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<List<VideoModel>>(
        future: _videosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay videos disponibles"));
          }

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return VideoItem(video: snapshot.data![index]);
            },
          );
        },
      ),
    );
  }
}
