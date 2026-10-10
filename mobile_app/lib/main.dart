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
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
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
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();

        final mediaQuery = MediaQuery.of(context);
        final isAndroid = Theme.of(context).platform == TargetPlatform.android;

        // Differentiate between traditional Android 3-button navigation and gesture navigation:
        // - In gesture navigation: systemGestureInsets on left/right are > 0 (side back swipes enabled),
        //   and content remains full-bleed without unnecessary blank bottom padding.
        // - In three-button navigation: systemGestureInsets on left/right are 0.0, and the system
        //   navigation bar height is typically >= 36-48dp.
        final isGestureMode = mediaQuery.systemGestureInsets.left > 0.0 ||
            mediaQuery.systemGestureInsets.right > 0.0;
        final isThreeButtonMode = isAndroid &&
            !isGestureMode &&
            mediaQuery.padding.bottom >= 36.0;

        final bottomInset = isThreeButtonMode ? mediaQuery.padding.bottom : 0.0;

        if (bottomInset > 0) {
          return ColoredBox(
            color: AppTheme.bgDark,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: MediaQuery(
                data: mediaQuery.copyWith(
                  padding: mediaQuery.padding.copyWith(bottom: 0.0),
                  viewPadding: mediaQuery.viewPadding.copyWith(bottom: 0.0),
                ),
                child: child,
              ),
            ),
          );
        }

        return child;
      },
    );
  }
}
