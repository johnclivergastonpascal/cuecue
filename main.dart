import 'package:cuecue/notification/callbackDispatcher.dart';
import 'package:cuecue/notification/notification_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:stack_appodeal_flutter/stack_appodeal_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:cuecue/screen/main_screen.dart';

void main() async {
  // 1. Asegura que los bindings de Flutter estén listos
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializar Workmanager para las notificaciones cada 2 horas
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false, // Cámbialo a true para ver logs en consola
  );

  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  await notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();

  // 3. Registrar la tarea periódica (mínimo 15 min por Android, pusimos 2 horas)
  await Workmanager().registerPeriodicTask(
    "videoTask",
    "checkNewVideo",
    initialDelay: const Duration(hours: 2),
  );

  // 4. Inicialización de Appodeal antes de runApp
  await Appodeal.initialize(
    appKey: "a65c3aee15b484cb9e4833fcc63d4786de15d50b408ccad2",
    adTypes: [
      AppodealAdType.Banner,
      AppodealAdType.Interstitial,
      AppodealAdType.MREC,
    ],
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationRouter.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: MainScreen(),
    );
  }
}
