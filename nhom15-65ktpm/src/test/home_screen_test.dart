import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soroban_kids_app/core/services/audio_service.dart';
import 'package:soroban_kids_app/core/services/storage_service.dart';
import 'package:soroban_kids_app/features/2_gamification_parent/presentation/screens/home_screen.dart';
import 'package:soroban_kids_app/injection_container.dart';
import 'package:soroban_kids_app/shared/widgets/kid_card.dart';

class _TestAudioService implements AudioService {
  @override
  Future<void> playBeadClick() async {}

  @override
  Future<void> playEncouragementFeedback([String? explanation]) async {}

  @override
  Future<void> playSuccessFeedback([String? customPraise]) async {}

  @override
  Future<void> speak(String text) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'soroban_child_profile': jsonEncode({
        'id': 'test-child',
        'name': 'Linh',
        'age': 5,
        'streakCount': 8,
        'lastActiveDate': '2026-11-23',
        'unlockedBadgeIds': <String>[],
        'currentLevel': 1,
      }),
      'daily_reminder_enabled': false,
    });
    await sl.reset();
    sl.registerSingleton<AudioService>(_TestAudioService());
    sl.registerSingleton<StorageService>(StorageService());
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('HomeScreen shows service streak and four learning actions',
      (WidgetTester tester) async {
    final previousSize = tester.view.physicalSize;
    final previousDevicePixelRatio = tester.view.devicePixelRatio;
    addTearDown(() {
      tester.view.physicalSize = previousSize;
      tester.view.devicePixelRatio = previousDevicePixelRatio;
    });

    for (final size in [
      const Size(320, 640),
      const Size(768, 1024),
      const Size(1024, 768),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chào bé Linh!'), findsOneWidget);
      expect(find.text('8 ngày'), findsOneWidget);
      expect(find.byType(KidCard), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    }
  });
}
