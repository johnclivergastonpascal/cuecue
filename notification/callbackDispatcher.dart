import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final FlutterLocalNotificationsPlugin notifications =
        FlutterLocalNotificationsPlugin();

    // 1. Inicialización de notificaciones
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_notification');
    await notifications.initialize(
      settings: const InitializationSettings(android: androidInit),
    );

    // 2. Canales a rastrear
    final List<String> channels = [
      'CinePulseChannel',
      'combofilm',
      'LCHDORAMAS',
      'NovelasHDTM',
    ];

    try {
      // 3. Consultar todos los canales en paralelo (Igual que en tu UI)
      final requests = channels.map((channel) {
        return http
            .get(
              Uri.parse(
                'https://api.dailymotion.com/user/$channel/videos?fields=id,title,thumbnail_720_url&limit=1',
              ),
            )
            .timeout(const Duration(seconds: 10));
      }).toList();

      final responses = await Future.wait(requests);
      final prefs = await SharedPreferences.getInstance();

      // Obtenemos el último ID notificado para no repetir
      String? lastNotifiedId = prefs.getString('last_notified_video_id');

      Map<String, dynamic>? newestVideo;

      for (var response in responses) {
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['list'] != null && data['list'].isNotEmpty) {
            final video = data['list'][0];

            // Si el video más reciente de este canal es el que ya notificamos antes, lo ignoramos
            if (video['id'] != lastNotifiedId) {
              newestVideo = video;
              break; // Notificamos el primero que encontremos que sea nuevo
            }
          }
        }
      }

      // 4. Si encontramos un video nuevo, disparamos la notificación
      if (newestVideo != null) {
        String title = newestVideo['title'];
        String videoId = newestVideo['id'];
        String? imageUrl = newestVideo['thumbnail_720_url'];

        // Guardamos este ID para que la próxima vez sepamos que ya se mostró
        await prefs.setString('last_notified_video_id', videoId);

        BigPictureStyleInformation? style;
        if (imageUrl != null) {
          final filePath = await _downloadImage(imageUrl);
          style = BigPictureStyleInformation(
            FilePathAndroidBitmap(filePath),
            largeIcon: FilePathAndroidBitmap(filePath),
            contentTitle: title,
            summaryText: 'Nuevo estreno disponible',
          );
        }

        final AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
              'video_channel',
              'Nuevos Videos',
              channelDescription: 'Notificaciones de contenido nuevo',
              importance: Importance.max,
              priority: Priority.high,
              styleInformation: style,
            );

        await notifications.show(
          id: 1, // ID fijo para que una notificación nueva reemplace a la anterior
          title: title,
          body: '¡Hay nuevo contenido en tus canales favoritos!',
          notificationDetails: NotificationDetails(android: androidDetails),
          payload: videoId,
        );
      }
    } catch (e) {
      print("Error en Workmanager: $e");
    }

    return Future.value(true);
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
