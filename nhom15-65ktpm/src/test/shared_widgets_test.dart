import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soroban_kids_app/core/constants/app_colors.dart';
import 'package:soroban_kids_app/shared/widgets/kid_button.dart';
import 'package:soroban_kids_app/shared/widgets/kid_card.dart';
import 'package:soroban_kids_app/shared/widgets/kid_decoration.dart';
import 'package:soroban_kids_app/shared/widgets/kid_progress_bar.dart';
import 'package:soroban_kids_app/shared/widgets/kid_status_icon.dart';

void main() {
  testWidgets('KidButton supports an icon-only accessible 48dp target',
      (WidgetTester tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: KidButton(
              onPressed: () => tapped = true,
              icon: Icons.back_hand_rounded,
              semanticLabel: 'Tập đếm',
              width: 32,
              height: 32,
            ),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(KidButton));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(
      find.ancestor(
        of: find.byType(AnimatedScale),
        matching: find.byType(InkWell),
      ),
      findsOneWidget,
    );

    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Tập đếm'), findsOneWidget);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(KidButton)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(
        tester.getSize(find.byType(InkWell)).height, greaterThanOrEqualTo(48));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
    semantics.dispose();
  });

  testWidgets('KidButton selects accessible foregrounds for brand colors',
      (WidgetTester tester) async {
    for (final backgroundColor in [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accentPurple,
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: KidButton(
                onPressed: () {},
                icon: Icons.play_arrow_rounded,
                semanticLabel: 'Bắt đầu',
                backgroundColor: backgroundColor,
              ),
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.play_arrow_rounded));
      expect(_contrastRatio(backgroundColor, icon.color!),
          greaterThanOrEqualTo(4.5));
    }
  });

  testWidgets('KidCard supports a tap and content padding',
      (WidgetTester tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KidCard(
            semanticLabel: 'Thẻ học tập',
            onTap: () => tapped = true,
            child: const Text('⭐'),
          ),
        ),
      ),
    );

    expect(find.text('⭐'), findsOneWidget);
    final size = tester.getSize(find.byType(KidCard));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    await tester.tap(find.byType(KidCard));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('KidProgressBar exposes progress and semantic value',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KidProgressBar(
            value: 0.6,
            semanticLabel: 'Tiến trình học',
          ),
        ),
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Tiến trình học'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Tiến trình học')).value,
      '60%',
    );
    semantics.dispose();
  });

  testWidgets('KidStatusIcon provides a status label',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KidStatusIcon(
            status: KidStatusType.success,
            semanticLabel: 'Đã hoàn thành',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Đã hoàn thành'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('KidDecoration is decorative and uses the shared palette',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KidDecoration(
            type: KidDecorationType.flower,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.local_florist_rounded), findsOneWidget);
    expect(tester.getSize(find.byType(KidDecoration)), const Size(48, 48));
  });

  testWidgets('shared widgets fit narrow and wide viewports',
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
      const Size(1200, 900),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                KidButton(
                  onPressed: () {},
                  icon: Icons.play_arrow_rounded,
                  label: 'Bắt đầu',
                ),
                KidCard(
                  child: KidProgressBar(
                    value: 0.5,
                    semanticLabel: 'Tiến trình',
                  ),
                ),
                const KidStatusIcon(status: KidStatusType.info),
                const KidDecoration(
                  type: KidDecorationType.star,
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    }
  });
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter =
      firstLuminance > secondLuminance ? firstLuminance : secondLuminance;
  final darker =
      firstLuminance > secondLuminance ? secondLuminance : firstLuminance;

  return (lighter + 0.05) / (darker + 0.05);
}
