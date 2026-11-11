import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cricketverse_ai/screens/auth_screen.dart';
import 'package:cricketverse_ai/core/widgets/forgot_password_sheet.dart';
import 'package:cricketverse_ai/services/socket_service.dart';
import 'package:cricketverse_ai/services/storage_service.dart';
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class _FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int playerId) async {}

  @override
  Future<int?> create(DataSource dataSource) async => 1;

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async => 1;

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) =>
      const Stream<VideoEvent>.empty();

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Widget buildView(int playerId) => const SizedBox.shrink();
}

class _FakeStorageService extends StorageService {
  int lookupCallCount = 0;
  String? lastLookedUpEmail;
  Completer<Map<String, dynamic>>? pendingLookup;
  Map<String, dynamic> nextLookupResponse = {
    'success': true,
    'found': true,
    'maskedPhone': '+91 ******7032',
    'hasVerifiedPhone': true,
    'flowRef': 'mock-flow-ref',
  };

  @override
  Future<Map<String, dynamic>> lookupForgotPasswordPhone(String email) async {
    lookupCallCount++;
    lastLookedUpEmail = email;
    if (pendingLookup != null) {
      return pendingLookup!.future;
    }
    return nextLookupResponse;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    VideoPlayerPlatform.instance = _FakeVideoPlayerPlatform();
  });

  tearDown(() {
    SocketService.disconnect();
  });

  Widget buildSubject(StorageService storage) {
    return ChangeNotifierProvider<StorageService>.value(
      value: storage,
      child: const MaterialApp(
        home: AuthScreen(),
      ),
    );
  }

  testWidgets(
      'Empty or whitespace-only email blocks popup, focuses field, and avoids API calls',
      (tester) async {
    tester.view.physicalSize = const Size(540, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final storage = _FakeStorageService();
    await tester.pumpWidget(buildSubject(storage));
    await tester.pump(const Duration(milliseconds: 200));

    final forgotBtn = find.text('Forgot?');
    await tester.ensureVisible(forgotBtn);
    await tester.tap(forgotBtn);
    await tester.pump();

    expect(find.text('Please enter your registered email first.'), findsOneWidget);
    expect(find.byType(ForgotPasswordSheet), findsNothing);
    expect(storage.lookupCallCount, 0);

    // Email field should receive focus automatically
    final editable = tester.widget<EditableText>(find.byType(EditableText).first);
    expect(editable.focusNode.hasFocus, isTrue);

    // Whitespace-only input is also treated as empty after trimming
    await tester.enterText(find.byType(TextFormField).first, '   ');
    await tester.pump();
    await tester.tap(forgotBtn);
    await tester.pump();

    expect(find.text('Please enter your registered email first.'), findsOneWidget);
    expect(find.byType(ForgotPasswordSheet), findsNothing);
    expect(storage.lookupCallCount, 0);

    SocketService.disconnect();
  });

  testWidgets(
      'Invalid email blocks popup, shows error, and clears when valid email entered',
      (tester) async {
    tester.view.physicalSize = const Size(540, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final storage = _FakeStorageService();
    await tester.pumpWidget(buildSubject(storage));
    await tester.pump(const Duration(milliseconds: 200));

    final emailField = find.byType(TextFormField).first;
    await tester.enterText(emailField, 'invalid-email');
    await tester.pump();

    final forgotBtn = find.text('Forgot?');
    await tester.ensureVisible(forgotBtn);
    await tester.tap(forgotBtn);
    await tester.pump();

    expect(find.text('Please enter a valid email address.'), findsOneWidget);
    expect(find.byType(ForgotPasswordSheet), findsNothing);
    expect(storage.lookupCallCount, 0);

    // Entering a valid email clears the validation error
    await tester.enterText(emailField, 'user@example.com');
    await tester.pump();
    expect(find.text('Please enter a valid email address.'), findsNothing);

    SocketService.disconnect();
  });

  testWidgets(
      'Valid email trims whitespace, opens popup, fetches phone, and prevents duplicate taps',
      (tester) async {
    tester.view.physicalSize = const Size(540, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final storage = _FakeStorageService()
      ..pendingLookup = Completer<Map<String, dynamic>>();
    await tester.pumpWidget(buildSubject(storage));
    await tester.pump(const Duration(milliseconds: 200));

    final emailField = find.byType(TextFormField).first;
    await tester.enterText(emailField, '  chirag@example.com  ');
    await tester.pump();

    final forgotBtn = find.text('Forgot?');
    await tester.ensureVisible(forgotBtn);
    await tester.tap(forgotBtn);
    await tester.tap(forgotBtn, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ForgotPasswordSheet), findsOneWidget);
    expect(storage.lookupCallCount, 1);
    expect(storage.lastLookedUpEmail, 'chirag@example.com');
    expect(find.text('Fetching your registered mobile number...'), findsOneWidget);

    storage.pendingLookup!.complete({
      'success': true,
      'found': true,
      'maskedPhone': '+91 ******7032',
      'hasVerifiedPhone': true,
      'flowRef': 'mock-flow-ref',
    });
    await tester.pumpAndSettle();

    expect(find.text('+91 ******7032'), findsOneWidget);

    SocketService.disconnect();
  });

  testWidgets(
      'Valid but unregistered email uses existing account lookup error handling',
      (tester) async {
    tester.view.physicalSize = const Size(600, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final storage = _FakeStorageService()
      ..nextLookupResponse = {
        'success': false,
        'found': false,
        'error': 'No account found with this email address.',
      };
    await tester.pumpWidget(buildSubject(storage));
    await tester.pump(const Duration(milliseconds: 200));

    final emailField = find.byType(TextFormField).first;
    await tester.enterText(emailField, 'unknown@example.com');
    await tester.pump();

    final forgotBtn = find.text('Forgot?');
    await tester.ensureVisible(forgotBtn);
    await tester.tap(forgotBtn);
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordSheet), findsOneWidget);
    expect(storage.lookupCallCount, 1);
    expect(find.text('No account found with this email address.'), findsOneWidget);

    SocketService.disconnect();
  });
}
