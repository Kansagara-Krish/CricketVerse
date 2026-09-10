// lib/main.dart
// CricketVerse AI — App Entry Point

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'services/notification_cache_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Initialize Auth storage, Hive CE notification cache, and FCM push notifications
  await ApiService.init();
  await NotificationCacheService.init();
  await NotificationService.init();

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
