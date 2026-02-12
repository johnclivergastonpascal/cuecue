import 'package:flutter/material.dart';
import 'package:cuecue/screen/main_screen.dart';

class NotificationRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static void openVideo(String videoId) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => MainScreen(initialVideoId: videoId)),
    );
  }
}
