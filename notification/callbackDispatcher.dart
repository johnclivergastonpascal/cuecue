import 'dart:convert';
import 'dart:io';
import 'package:cuecue/notification/notification_router.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    String? videoId;

    final FlutterLocalNotificationsPlugin notifications =
        FlutterLocalNotificationsPlugin();

    // 🔹 Inicialización (OBLIGATORIA)
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_notification');

    await notifications.initialize(
      settings: const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (response) {
        final videoId = response.payload;
        if (videoId != null) {
          NotificationRouter.openVideo(videoId);
        }
      },
    );

    String title = "¡Nuevo contenido disponible!";
    String? imageUrl;

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.dailymotion.com/user/CinePulseChannel/videos?fields=title,thumbnail_720_url,id&limit=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['list'] != null && data['list'].isNotEmpty) {
          title = data['list'][0]['title'];
          imageUrl = data['list'][0]['thumbnail_720_url'];
          videoId = data['list'][0]['id'];
        }
      }
    } catch (_) {}

    BigPictureStyleInformation? style;

    if (imageUrl != null) {
      final filePath = await _downloadImage(imageUrl);
      style = BigPictureStyleInformation(
        FilePathAndroidBitmap(filePath),
        largeIcon: FilePathAndroidBitmap(filePath),
        contentTitle: title,
        summaryText: 'Mira lo nuevo ahora',
      );
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'video_channel',
          'Nuevos Videos',
          channelDescription: 'Notificaciones de contenido nuevo',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: style, // ✅ AQUÍ VA
        );

    final androidPlugin = notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'video_channel',
        'Nuevos Videos',
        description: 'Notificaciones de contenido nuevo',
        importance: Importance.max,
      ),
    );

    await notifications.show(
      id: 1,
      title: title,
      body: 'Toca para ver el video',
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: videoId,
    );

    return true;
  });
}

Future<String> _downloadImage(String url) async {
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/notification.jpg';

  final response = await http.get(Uri.parse(url));
  final file = File(filePath);
  await file.writeAsBytes(response.bodyBytes);

  return filePath;
}
