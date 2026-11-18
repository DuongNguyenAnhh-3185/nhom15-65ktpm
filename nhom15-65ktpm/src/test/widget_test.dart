import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soroban_kids_app/shared/widgets/animated_icon_tile.dart';
import 'package:soroban_kids_app/shared/widgets/kid_button.dart';
import 'package:soroban_kids_app/shared/widgets/mascot_bubble.dart';

void main() {
  testWidgets('KidButton renders label and triggers callback on tap',
      (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KidButton(
            onPressed: () => tapped = true,
            label: 'Bắt Đầu',
          ),
        ),
      ),
    );

    expect(find.text('Bắt Đầu'), findsOneWidget);
    await tester.tap(find.text('Bắt Đầu'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets(
      'AnimatedIconTile animates, exposes an accessible label, and responds to taps',
      (WidgetTester tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedIconTile(
            icon: Icons.bolt_rounded,
            semanticLabel: 'Flash Anzan',
            color: Colors.purple,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.byTooltip('Flash Anzan'), findsOneWidget);
    expect(find.text('Flash Anzan'), findsNothing);
    final initialScale = tester
        .widget<Transform>(
          find.byKey(const ValueKey('animated-icon-motion')),
        )
        .transform
        .storage[0];

    await tester.pump(const Duration(milliseconds: 450));
    final animatedScale = tester
        .widget<Transform>(
          find.byKey(const ValueKey('animated-icon-motion')),
        )
        .transform
        .storage[0];
    expect(animatedScale, greaterThan(initialScale));

    await tester.tap(find.byTooltip('Flash Anzan'));
    expect(tapped, isTrue);
  });

  testWidgets('MascotBubbleWidget can replace its speech with an icon',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MascotBubbleWidget(
            speechText: 'A long spoken instruction',
            iconOnly: true,
          ),
        ),
      ),
    );

    expect(find.text('A long spoken instruction'), findsNothing);
    expect(find.byIcon(Icons.record_voice_over_rounded), findsOneWidget);
  });
}
