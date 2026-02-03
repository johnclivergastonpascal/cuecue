class VideoModel {
  final String id;
  final String title;
  final int duration;
  final String streamUrl;

  VideoModel({
    required this.id,
    required this.title,
    required this.duration,
    required this.streamUrl,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json, String url) {
    return VideoModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      duration: json['duration'] ?? 0,
      streamUrl: url,
    );
  }
}
