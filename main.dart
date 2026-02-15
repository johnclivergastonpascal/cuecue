import 'package:cuecue/notification/callbackDispatcher.dart';
import 'package:cuecue/notification/notification_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:stack_appodeal_flutter/stack_appodeal_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:cuecue/screen/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Workmanager
  await Workmanager().initialize(callbackDispatcher);

  // 2. Permisos de notificaciones
  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();
  await notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();

  // 3. Registrar tarea
  await Workmanager().registerPeriodicTask(
    "videoTask",
    "checkNewVideo",
    frequency: const Duration(hours: 2), // Asegúrate de usar 'frequency'
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );

  // 4. INICIALIZACIÓN DE APPODEAL MEJORADA
  // No bloqueamos el inicio de la app, dejamos que cargue en segundo plano
  Appodeal.setTesting(
    true,
  ); // <--- AGREGA ESTO PARA PROBAR (Quitar en producción)

  // Opcional: Configurar callbacks para saber si falla
  Appodeal.setBannerCallbacks(
    onBannerFailedToLoad: () => print("Banner falló"),
    onBannerLoaded: (isPrecache) => print("Banner cargado con éxito"),
  );

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
