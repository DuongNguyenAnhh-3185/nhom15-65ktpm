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
              width: 48,
              height: 32,
            ),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(KidButton));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));

    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Tập đếm'), findsOneWidget);
    await tester.tap(find.byType(KidButton));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
    semantics.dispose();
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
            icon: Icons.auto_awesome_rounded,
            color: AppColors.accentPurple,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
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

    for (final size in [const Size(320, 640), const Size(1200, 900)]) {
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
                  icon: Icons.star_rounded,
                  color: AppColors.secondary,
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
