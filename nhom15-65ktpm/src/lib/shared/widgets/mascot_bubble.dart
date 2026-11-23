import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'panda_mascot.dart';

class MascotBubbleWidget extends StatelessWidget {
  final String speechText;
  final VoidCallback? onMascotTap;
  final PandaExpression expression;
  final Map<PandaExpression, ImageProvider> expressionImages;

  const MascotBubbleWidget({
    super.key,
    required this.speechText,
    this.onMascotTap,
    this.expression = PandaExpression.happy,
    this.expressionImages = const {},
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Semantics(
          label: 'Linh vật Panda',
          button: onMascotTap != null,
          child: Material(
            color: AppColors.accentYellow,
            elevation: 3,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onMascotTap == null
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onMascotTap!();
                    },
              child: SizedBox(
                width: 84,
                height: 84,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.82, end: 1)
                              .animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: PandaMascot(
                      key: ValueKey(expression),
                      expression: expression,
                      image: expressionImages[expression],
                      size: 72,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.minTouchSize,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.tertiary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Text(
              speechText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onTertiary,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.start,
            ),
          ),
        ),
      ],
    );
  }
}
