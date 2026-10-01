// lib/main.dart
// CricketVerse AI — App Entry Point

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'services/notification_cache_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/elevenlabs_service.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'core/widgets/app_notification.dart' hide NotificationService;
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Initialize core services safely and concurrently
  await ApiService.init();
  Future.wait([
    NotificationCacheService.init(),
    NotificationService.init(),
    ElevenLabsService().init(),
  ]).catchError((e) {
    debugPrint('Background service init warning: $e');
    return <void>[];
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => StorageService(),
      child: const CricketVerseApp(),
    ),
  );
}

class CricketVerseApp extends StatelessWidget {
  const CricketVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppNotification.navigatorKey,
      title: 'CricketVerse AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      onGenerateRoute: AppRoutes.generateRoute,
      home: const SplashScreen(),
    );
  }
}
