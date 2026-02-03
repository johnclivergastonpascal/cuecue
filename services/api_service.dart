import 'dart:convert';
import 'package:cuecue/models/video_model.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Obtiene los usuarios desde GitHub
  Future<List<String>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://raw.githubusercontent.com/johnclivergastonpascal/cuecue/refs/heads/main/data/users.jsonl',
        ),
      );
      if (response.statusCode == 200) {
        // Limpiamos el formato JSONL para obtener una lista limpia de strings
        return response.body
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) => line.replaceAll('"', '').trim())
            .toList();
      }
    } catch (e) {
      print("Error GitHub: $e");
    }
    return [];
  }

  // Obtiene los videos y su metadata (el stream .m3u8)
  Future<List<VideoModel>> fetchAllVideos() async {
    List<VideoModel> allVideos = [];
    List<String> users = await getUsers();

    for (String user in users.take(5)) {
      // Procesamos los primeros 5 usuarios
      final url =
          'https://api.dailymotion.com/user/$user/videos?fields=id,title,duration&limit=5';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        for (var item in data['list']) {
          String? m3u8 = await _getStreamUrl(item['id']);
          if (m3u8 != null) {
            allVideos.add(VideoModel.fromJson(item, m3u8));
          }
        }
      }
    }
    return allVideos;
  }

  Future<String?> _getStreamUrl(String videoId) async {
    try {
      final res = await http.get(
        Uri.parse('https://www.dailymotion.com/player/metadata/video/$videoId'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return data['qualities']['auto'][0]['url'];
      }
    } catch (_) {}
    return null;
  }
}
